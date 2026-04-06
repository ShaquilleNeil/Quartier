//
//  SafariView.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-04-06.
//


import SafariServices
import SwiftUI

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uvc: SFSafariViewController, context: Context) {}
}
