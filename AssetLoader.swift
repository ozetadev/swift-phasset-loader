//
//  AssetLoader.swift
//  videoRenderer
//
//  Created by Philip Bernstein on 11/17/16.
//  Copyright © 2016 Philip Bernstein. All rights reserved.
//

import Foundation
import Photos
import AVKit
import AVFoundation

/*
    Class designed to asyncrhonously load PHAssets from the users photo library, using the Photos framework. While I'd like to use ALAssets, that has been deprecetaed, so we shall work with what we have.
 
    This class would theoretically be used to select videos or photos for background to lyric rendering.
 */

class AssetLoader : NSObject {
    
    var photoAuthorization:Bool? = false // whether or not we have authorization
    var completionCallback: ((_ success: Bool, _ assets: NSArray) -> ())? // completion callback for fetching assets
    var imageCallback: ((_ success: Bool, _ image: UIImage) -> ())? // callback for fetching UIImage
    var assetCallback: ((_ success: Bool, _ asset: AVAsset, _ audioMix:AVAudioMix) -> ())? // callback for fetching video asset
    var collectionToUse:PHAssetCollection? // collection we want to catalog
    var loadedContent:NSMutableArray? // array of content we have loaded (phassets)
    
    /*
        Checks if we have permission to access photo library, if not, requests access to photo library
    */
    func requestPermission() {
        if (self.checkPermission() == true) { // we have permission
            return // already authorized
        }
        else  { // we need permission, requesting
            PHPhotoLibrary.requestAuthorization({ (authorizationStatus) in
                var authorized:Bool? = false
                let authorizationStatus:PHAuthorizationStatus! = PHPhotoLibrary.authorizationStatus()
                
                if (authorizationStatus == PHAuthorizationStatus.authorized || authorizationStatus == PHAuthorizationStatus.restricted) {
                    authorized = true
                }
                
                self.photoAuthorization = authorized
                
                if (authorized)! { // now that we are permitted, load a list of PHAssets that we can use
                    self.loadAssets()
                }
            })
        }
    }
    
    /*
        Simply checks current photo library authorization status
    */
    func checkPermission()->Bool! {
        
        var authorized:Bool? = false
        let authorizationStatus:PHAuthorizationStatus! = PHPhotoLibrary.authorizationStatus()
        
        if (authorizationStatus == PHAuthorizationStatus.authorized || authorizationStatus == PHAuthorizationStatus.restricted) {
            authorized = true
        }
        
        self.photoAuthorization = authorized
        
        return authorized;
    }
    
    /*
        Loads assets using Photos library, returned as PHAssets, sorted by date taken
    */
    
    func loadAssets() {
        
        // no permission, we return an empty array as our callback
        if (self.photoAuthorization == false && self.completionCallback != nil) {
            self.completionCallback!(false, [])
            return
        }
        
        
        // we want to sort by creation date, newest first
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let collection:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        var assetCollection:PHAssetCollection?
        
        assetCollection = collection.firstObject;
        self.collectionToUse = assetCollection;

        let photoAssets = PHAsset.fetchAssets(in: assetCollection!, options: nil)
        let content:NSMutableArray = NSMutableArray()
        
        photoAssets.enumerateObjects({ (asset, index, unsafe) in
            content.add(asset)
        })
        
        // end result is array of assets that we can use
        self.loadedContent = content
        
        if ((self.completionCallback) != nil) {
            self.completionCallback!(true, self.loadedContent!)
        }
        
    }
    
    func loadImageForAsset(asset: PHAsset) {
        let options = PHImageRequestOptions()
        options.resizeMode = .exact
        
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize.init(width: 1024, height: 1024), contentMode: .aspectFill, options: options, resultHandler: {(result, info)in
            
            if (self.imageCallback != nil) {
                self.imageCallback!(true, result!)
            }
        })
    }
    
    func loadAssetForVideo(asset: PHAsset) {
        let options: PHVideoRequestOptions = PHVideoRequestOptions()
        options.version = .original
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: {(resultAsset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
            
            if (self.assetCallback != nil) {
                self.assetCallback!(true, resultAsset!,audioMix!)
            }
        })
}
    

    
}
