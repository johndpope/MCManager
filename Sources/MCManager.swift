/**
 Copyright 2016 Aeta

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import MultipeerConnectivity

@available(iOS 9, *)
@available(OSX 10.12, *)
@available(watchOS 3, *)
public protocol MCManagerDelegate: class {
    func manager(_ manager: MCManager, peer peerID: MCPeerID, didChange state: MCSessionState)
    func manager(_ manager: MCManager, didReceive data: Data, fromPeer peerID: MCPeerID)
    func manager(_ manager: MCManager, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress)
    func manager(_ manager: MCManager, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?)
    func manager(_ manager: MCManager, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID)
    func manager(_ manager: MCManager, recievingProgress progress: Progress)
}

/**
 Manages all necessary components for MultipeerConnectivity to function properly
 */
@available(iOS 9, *)
@available(OSX 10.12, *)
@available(watchOS 3, *)
open class MCManager: NSObject {
    public weak var delegate: MCManagerDelegate?

    public private(set) var peerID: MCPeerID
    public private(set) var browser: MCBrowserViewController
    private var serviceType: String
    private var session: MCSession
    private var advertiser: MCAdvertiserAssistant

    public var shouldAdvertiseSelf: Bool = true {
        didSet {
            shouldAdvertiseSelf ? advertiser.start() : advertiser.stop()
        }
    }

    public init(withDisplayName displayName: String, serviceType type: String) {
        self.serviceType = type
        self.peerID = MCPeerID(displayName: displayName)
        self.session = MCSession(peer: peerID)
        self.browser = MCBrowserViewController(serviceType: self.serviceType, session: session)
        self.advertiser = MCAdvertiserAssistant(serviceType: self.serviceType, discoveryInfo: nil, session: session)

        super.init()

        session.delegate = self
    }

    public func send(someData data: Data, to peer: MCPeerID? = nil, completion: (Error?) -> Void) {
        let destination = peer != nil ? [peer!] : session.connectedPeers
        do {
            try self.session.send(data, toPeers: destination, with: .reliable)
        } catch {
            completion(error)
        }
    }
}

@available(iOS 9, *)
@available(OSX 10.12, *)
@available(watchOS 3, *)
extension MCManager: MCSessionDelegate {
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        self.delegate?.manager(self, peer: peerID, didChange: state)
    }

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        self.delegate?.manager(self, didReceive: data, fromPeer: peerID)
    }

    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        self.delegate?.manager(self, didStartReceivingResourceWithName: resourceName, fromPeer: peerID, with: progress)
        DispatchQueue.main.async(execute: {
            progress.addObserver(self, forKeyPath: "fractionCompleted", options: [.new], context: nil)
        })
    }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        self.delegate?.manager(self, didFinishReceivingResourceWithName: resourceName, fromPeer: peerID, at: localURL, withError: error)
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        self.delegate?.manager(self, didReceive: stream, withName: streamName, fromPeer: peerID)
    }
}
