import Foundation

class QiitaClient: BaseClient {
    let root = "http://qiita.com"
    
    func call<T: BaseRequest>(request: T, callback: (T.BaseResponse) -> Void) {
        let feedUrl = NSURL(string: root + "/" + request.path)!
        let urlRequest: NSURLRequest = NSURLRequest(URL: feedUrl)
        let queue: NSOperationQueue = NSOperationQueue.mainQueue()
        
        // リクエスト
        NSURLConnection.sendAsynchronousRequest(urlRequest, queue: queue) {
            res, data, error in
            
            if error != nil {
                println("通信エラーだよ")
                return
            }
            
            
            // httpレスポンスとして扱う
            let httpResponse = res as! NSHTTPURLResponse
            if httpResponse.statusCode != 200 {
                println("エラー応答だよ")
            }
            
            if let response = request.makeResponse(data) {
                callback(response)
            }
        }
    }
    
    class FeedRequest: BaseRequest {
        let path = "tags/Swift/feed.atom"
        let xmlParseDelegate: XMLParseDelegate
        
        init (xmlParseDelegate: XMLParseDelegate) {
            self.xmlParseDelegate = xmlParseDelegate
        }
        
        typealias BaseResponse = Void
        
        func makeResponse(data: NSData) -> BaseResponse? {
            let xmlParser = NSXMLParser(data: data)
            xmlParser.delegate = xmlParseDelegate
            xmlParser.parse()
            return nil
        }
    }
}