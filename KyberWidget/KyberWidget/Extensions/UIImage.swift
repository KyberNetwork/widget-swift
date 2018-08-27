//
//  UIImage+Kyber.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit

extension UIImage {
  func resizeImage(to newSize: CGSize?) -> UIImage? {
    guard let size = newSize else { return self }
    if self.size == size { return self }

    let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)

    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    self.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage ?? self
  }
}
