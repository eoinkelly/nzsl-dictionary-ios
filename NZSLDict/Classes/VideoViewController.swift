import Foundation
import MediaPlayer

class VideoViewController: UIViewController, UISearchBarDelegate {
    var currentEntry: DictEntry!
    var detailView: DetailView!
    var videoBack: UIView!
    var networkErrorMessage: UIView!
    var activity: UIActivityIndicatorView!
    var player: MPMoviePlayerController!
    var delegate: ViewControllerDelegate!
    var reachability: Reachability?

    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.tabBarItem = UITabBarItem(title: "Video", image: UIImage(named: "movie"), tag: 0)
        NotificationCenter.default.addObserver(self, selector: #selector(VideoViewController.showEntry(_:)), name: NSNotification.Name(rawValue: EntrySelectedName), object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        reachability?.stopNotifier()
        reachability = nil
    }

    override func loadView() {
        let view: UIView = UIView(frame: UIScreen.main.bounds)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        detailView = DetailView(frame: CGRectMake(0, 0, view.bounds.size.width, DetailView.height))
        detailView.autoresizingMask = [.FlexibleWidth]
        view.addSubview(detailView)
        videoBack = UIView(frame: CGRect(x: 0, y: DetailView.height, width: view.bounds.size.width, height: view.bounds.size.height - DetailView.height))
        videoBack.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(videoBack)

        networkErrorMessage = UIView.init(frame: videoBack.frame)
        networkErrorMessage.autoresizingMask = detailView.autoresizingMask
        networkErrorMessage.backgroundColor = UIColor.whiteColor()
        let networkErrorMessageImage = UIImageView.init(frame: CGRectMake(0, 24, networkErrorMessage.frame.width, 72))
        networkErrorMessageImage.image = UIImage.init(named: "ic_videocam_off")
        networkErrorMessageImage.contentMode = .Center

        let networkErrorMessageText = UITextView.init(frame: CGRectMake(0, 24 + networkErrorMessageImage.frame.height, networkErrorMessage.frame.width, 100))
        networkErrorMessageText.textAlignment = .Center
        networkErrorMessageText.text = "Playing videos requires access to the Internet."

        networkErrorMessage.addSubview(networkErrorMessageImage)
        networkErrorMessage.addSubview(networkErrorMessageText)
        networkErrorMessage.autoresizesSubviews = true
        view.addSubview(networkErrorMessage)


        setupNetworkStatusMonitoring()

        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if self.responds(to: #selector(getter: UIViewController.edgesForExtendedLayout)) {
            self.edgesForExtendedLayout = UIRectEdge()
        }


       reachability!.startNotifier()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.showCurrentEntry()

    }

    func setupNetworkStatusMonitoring() {
        reachability = Reachability.reachabilityForInternetConnection()


        reachability!.reachableBlock = { (reach: Reachability?) -> Void in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            dispatch_async(dispatch_get_main_queue()) {
                self.networkErrorMessage.hidden = true
                self.videoBack.hidden = false

            }
        }

        reachability!.unreachableBlock = { (reach: Reachability?) -> Void in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            dispatch_async(dispatch_get_main_queue()) {
                self.networkErrorMessage.hidden = false
                self.videoBack.hidden = true
            }
        }

        if reachability?.currentReachabilityStatus() != .NotReachable {
            reachability?.reachableBlock(reachability)
        }

    }


    func showEntry(_ notification: Notification) {
        currentEntry = notification.userInfo!["entry"] as! DictEntry
        player = nil
    }

    func showCurrentEntry() {
        detailView.showEntry(currentEntry)
        self.perform(#selector(VideoViewController.startVideo), with: nil, afterDelay: 0)
    }

    func startVideo() {
        player = MPMoviePlayerController(contentURL: URL(string: currentEntry.video)!)
        NotificationCenter.default.addObserver(self, selector: #selector(VideoViewController.playerPlaybackStateDidChange(_:)), name: NSNotification.Name.MPMoviePlayerPlaybackStateDidChange, object: player)
        NotificationCenter.default.addObserver(self, selector: #selector(VideoViewController.playerPlaybackDidFinish(_:)), name: NSNotification.Name.MPMoviePlayerPlaybackDidFinish, object: player)
        player.prepareToPlay()
        player.view!.frame = videoBack.bounds
        player.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        videoBack.addSubview(player.view!)
        player.play()


        activity = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        videoBack.addSubview(activity)
        activity.frame = activity.frame.offsetBy(dx: (videoBack.bounds.size.width - activity.bounds.size.width) / 2, dy: (videoBack.bounds.size.height - activity.bounds.size.height) / 2)
        activity.startAnimating()
    }


    func playerPlaybackStateDidChange(_ notification: Notification) {
        if activity == nil { return }

        activity.stopAnimating()
        activity.removeFromSuperview()
        activity = nil
    }

    func playerPlaybackDidFinish(_ notification: Notification) {
        guard let userInfo: NSDictionary = notification.userInfo as NSDictionary?  else { return }
        guard let rawReason = userInfo[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] as? Int else { return }
        guard let reason: MPMovieFinishReason = MPMovieFinishReason(rawValue: rawReason) else { return }

        switch reason {
        case .PlaybackError:
            networkErrorMessage.hidden = false
            videoBack.hidden = true
        default: break
        }
    }
}
