//
//  ViewController.swift
//  FileManager
//
//  Created by Админ on 01.07.2021.
//

import UIKit
import PhotosUI

var documentsUrl = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask,   appropriateFor: nil, create: false)

class FileManagerViewController: UIViewController, AlertPresenter {
    
    //MARK: - Properties
    var directory: Directory
    
    private var directoryName: String?
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
        tableView.dataSource = self
        tableView.delegate = self
        
        return tableView
    }()

    // MARK: - Initializers
    required init?(coder: NSCoder) {
        directory = Directory(at: Directory.rootUrl)
        super.init(coder: coder)
        title = "Documents"
    }
    
    init(title: String, url: URL) {
        directory = Directory(at: url)
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        print(type(of: self), #function)
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Add directory", style: .plain, target: self, action: #selector(addDirectory(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add photo", style: .plain, target: self, action: #selector(addPhoto(_:)))
        
        setupSubviews()
    }
    
    // MARK: - Private methods
    private func setupSubviews() {
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }


    // MARK: - Actions
    @objc private func addDirectory(_ sender: Any) {
        print(type(of: self), #function, type(of: sender))
        
        directoryName = nil
        
        let alertController = UIAlertController(title: "New directory", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Enter directory name"
            textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        }
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] action in
            guard let self = self,
                  let name = self.directoryName else { return }
            self.directory.createDirectory(name) { result in
                switch result {
                case .failure(let error):
                    self.presentErrorAlert(error.localizedDescription)
                case .success(let row):
                    DispatchQueue.main.async {
                        self.tableView.insertRows(at: [IndexPath(row: row, section: 0)], with: .top)
                    }
                }
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        navigationController?.present(alertController, animated: true, completion: nil)
    }
    
    @objc private func textFieldDidChange(_ sender: Any) {
        guard let textField = sender as? UITextField else {
            return
        }
        directoryName = textField.text
    }
    
    @objc private func addPhoto(_ sender: Any) {
        print(type(of: self), #function, type(of: sender))
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
}

//MARK: - UITableViewDataSource
extension FileManagerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        directory.objects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self)) else {
            return UITableViewCell()
        }
        
        let fileSystemObject = directory.objects[indexPath.row]
        cell.textLabel?.text = fileSystemObject.name
        
        switch fileSystemObject.type {
        case .file:
            cell.imageView?.image = UIImage(systemName: "photo")
            cell.accessoryType = .none
        case .directory:
            cell.imageView?.image = UIImage(systemName: "folder")
            cell.accessoryType = .disclosureIndicator
        default:
            cell.imageView?.image = UIImage(systemName: "folder")
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let fsObject = directory.objects[indexPath.row]
        
        let alertTitle = "Удалить \(fsObject.type == .directory ? "папку" : "файл") \"\(fsObject.name)\"?"
        
        let alertController = UIAlertController(title: alertTitle, message: "Действие нельзя будет отменить", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Да, удалить", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            self.directory.deleteItem(at: indexPath.row) { result in
                switch result {
                case .failure(let error):
                    self.presentErrorAlert(error.localizedDescription)
                case .success(_):
                    tableView.deleteRows(at: [indexPath], with: .bottom)
                }
            }
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
        
        navigationController?.present(alertController, animated: true, completion: nil)
    }
}

//MARK: - UITableViewDelegate
extension FileManagerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let fsObject = directory.objects[indexPath.row]
        if fsObject.type == .directory {
            let vc = FileManagerViewController(title: fsObject.name, url: fsObject.url)
            navigationController?.pushViewController(vc, animated: true)
        } else if fsObject.type == .up {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let fsObject = directory.objects[indexPath.row]
        guard fsObject.type != .up else { return .none }
        return .delete
    }
}

// MARK: - PHPickerViewControllerDelegate

extension FileManagerViewController:  UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let file = UUID().uuidString + ".jpg"
        let imageUrl = documentsUrl!.appendingPathComponent(file)
        
        if let image = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerEditedImage")] as? UIImage {
            
            if let data = image.jpegData(compressionQuality: 1.0),
               !FileManager.default.fileExists(atPath: imageUrl.path) {
                
                do {
                    try data.write(to: imageUrl)
                    print("file saved as \(imageUrl)")
                    self.directory.moveItem(from: imageUrl) { result in
                        switch result {
                        case .failure(let error):
                            DispatchQueue.main.async {
                                self.presentErrorAlert(error.localizedDescription)
                            }
                        case .success(let row):
                            DispatchQueue.main.async {
                                self.tableView.insertRows(at: [IndexPath(row: row, section: 0)], with: .top)
                            }
                        }
                    }
                    
                } catch {
                    
                    print("error:", error)
                    
                }
            }
        }
       
        picker.dismiss(animated: true, completion: nil)
        
        DispatchQueue.main.async{
            self.tableView.reloadData()
        }
 
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
