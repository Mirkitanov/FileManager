//
//  AlertPresenter.swift
//  FileManager
//
//  Created by Админ on 01.07.2021.
//

import UIKit

public protocol AlertPresenter: UIViewController {
    func presentAlert(title: String, message: String)
    func presentErrorAlert(_ message: String)
}

public extension AlertPresenter {
    func presentAlert(title: String, message: String) {
        self.present(AlertFactory.makeInfoAlert(title: title, message: message), animated: true, completion: nil)
    }
    
    func presentErrorAlert(_ message: String) {
        self.present(AlertFactory.makeErrorAlert(message), animated: true, completion: nil)
    }
}

