//
//  HideKeyboard.swift
//  CloudKitEx
//
//  Created by Luthfor Khan on 5/13/22.
//

import Foundation
import SwiftUI

// Hacking With Swift
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
