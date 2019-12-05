//
//  Fonts.swift
//  Horo
//
//  Created by Andrey Chernyshev on 05/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

final class Font {
    final class Poppins {
        static func regular(size: CGFloat) -> UIFont {
            return UIFont(name: "Poppins-Regular", size: size)!
        }
        
        static func bold(size: CGFloat) -> UIFont {
            return UIFont(name: "Poppins-Bold", size: size)!
        }
        
        static func medium(size: CGFloat) -> UIFont {
            return UIFont(name: "Poppins-Medium", size: size)!
        }
        
        static func semibold(size: CGFloat) -> UIFont {
            return UIFont(name: "Poppins-Semibold", size: size)!
        }
        
        static func light(size: CGFloat) -> UIFont {
            return UIFont(name: "Poppins-Light", size: size)!
        }
    }
    
    final class OpenSans {
        static func regular(size: CGFloat) -> UIFont {
            return UIFont(name: "OpenSans", size: size)!
        }
        
        static func bold(size: CGFloat) -> UIFont {
            return UIFont(name: "OpenSans-Bold", size: size)!
        }
        
        static func semibold(size: CGFloat) -> UIFont {
            return UIFont(name: "OpenSans-Semibold", size: size)!
        }
        
        static func light(size: CGFloat) -> UIFont {
            return UIFont(name: "OpenSans-Light", size: size)!
        }
        
        static func italic(size: CGFloat) -> UIFont {
            return UIFont(name: "OpenSans-Italic", size: size)!
        }
    }
}
