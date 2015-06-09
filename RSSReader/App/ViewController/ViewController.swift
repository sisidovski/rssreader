import UIKit
import Foundation

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var articles: [Article] = []
    var selectedIndex: Int = 0
    let xmlParseDelegate: XMLParseDelegate = XMLParseDelegate()
    
    @IBOutlet weak var tableView: UITableView!

    @IBAction func onTouchRefresh(sender: UIBarButtonItem) {
        loadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.layoutMargins = UIEdgeInsetsZero
        var nib:UINib = UINib(nibName: "CustomTableViewCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: "Cell")
        loadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        // 選択されているcellがあれば解除
        if let index = tableView.indexPathForSelectedRow() {
            tableView.deselectRowAtIndexPath(index, animated: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedIndex = indexPath.row
        // webViewに遷移
        performSegueWithIdentifier("toWebView", sender: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        // webViewに遷移する場合は読み込むurlを設定する
        if (segue.identifier == "toWebView") {
            let subVC: WebViewController = segue.destinationViewController as! WebViewController
            subVC.url = articles[selectedIndex].url
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // 再利用するCellを取得する.
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! CustomTableViewCell
        // Cellに値を設定する.
        cell.nibTitleLabel.text = articles[indexPath.row].title
        cell.nibNameLabel.text = articles[indexPath.row].authorName
        cell.nibThumbnailView.image = ImageLoader.sharedInstance.getPlaceHolder(cell.nibThumbnailView.frame.size)
        
        // サムネイルがある場合はサムネイルを表示
        if let imageUrl = articles[indexPath.row].imgUrl {
            let mainQueue = dispatch_get_main_queue()
            let subQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
            
            // 画像の読み込みはサブのスレッドで非同期に行う
            dispatch_async(subQueue) {
                if let image = ImageLoader.sharedInstance.get(imageUrl, size: cell.nibThumbnailView.frame.size) {
                    dispatch_async(mainQueue) {
                        cell.nibThumbnailView.image = image
                        cell.setNeedsLayout()
                    }
                }
            }
        }

        return cell as UITableViewCell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if articles.count != 0  {
            // 高さ取得用のセル
            let stabCell = tableView.dequeueReusableCellWithIdentifier("Cell") as! CustomTableViewCell
            
            // そのままだとstoryboard上のサイズになってしまっているので、横幅を設定してlayoutsubviewsを呼ばせることによりcellを正しい形にする。
            stabCell.bounds.size.width = tableView.bounds.width
            stabCell.setNeedsLayout()
            stabCell.layoutIfNeeded()
            
            // 高さを取得
            let text = articles[indexPath.row].title
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
            let attributeDict = [
                NSFontAttributeName: UIFont.systemFontOfSize(16.0),
                NSParagraphStyleAttributeName: paragraphStyle
            ]
            let textSize = NSString(string: text).boundingRectWithSize(CGSizeMake(stabCell.nibTitleLabel.frame.width, 100), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: attributeDict, context: nil)
            return max(textSize.height + 60, 96)
        }
        return 100
    }
    
    func loadData() {
        let client = QiitaClient()
        xmlParseDelegate.addObserver(self, forKeyPath: "articles", options: .New, context: nil)
        client.call(QiitaClient.FeedRequest(xmlParseDelegate: self.xmlParseDelegate)){
            // KVOで変更を取得するのでcallbackはなし
        }
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        self.articles = self.xmlParseDelegate.articles
        self.tableView.reloadData()
    }
}
