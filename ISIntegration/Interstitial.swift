//
//  Interstitial.swift
//  ISIntegration
//
//  Created by Tomaz Treven on 19. 06. 24.
//  Copyright © 2024 ironsrc. All rights reserved.
//

protocol Interstitial {
    func Init(ui: InterstitialUi)
    func Load()
    func Show()
}
