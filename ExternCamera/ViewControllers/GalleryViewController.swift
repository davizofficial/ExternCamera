import UIKit
import AVKit

class GalleryViewController: UIViewController {
    
    private let storageManager = StorageManager.shared
    private var mediaFiles: [URL] = []
    private var currentStorageType: StorageType = .internal
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .black
        cv.register(MediaCell.self, forCellWithReuseIdentifier: "MediaCell")
        return cv
    }()
    
    private let storageSegmentedControl: UISegmentedControl = {
        let items = ["Internal", "External"]
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        return sc
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No photos or videos"
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMedia()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        title = "Gallery"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(didTapClose)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(didTapDeleteAll)
        )
        navigationItem.rightBarButtonItem?.tintColor = .red
        
        view.addSubview(storageSegmentedControl)
        view.addSubview(collectionView)
        view.addSubview(emptyLabel)
        
        storageSegmentedControl.addTarget(self, action: #selector(storageChanged), for: .valueChanged)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        storageSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            storageSegmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            storageSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            storageSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            storageSegmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            collectionView.topAnchor.constraint(equalTo: storageSegmentedControl.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func storageChanged() {
        currentStorageType = storageSegmentedControl.selectedSegmentIndex == 0 ? .internal : .external
        loadMedia()
    }
    
    private func loadMedia() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let useExternal = (self.currentStorageType == .external)
            let directory = self.storageManager.getSaveDirectory(forExternal: useExternal)
            
            do {
                let files = try FileManager.default.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: [.creationDateKey],
                    options: .skipsHiddenFiles
                )
                
                // Filter media files
                let mediaFiles = files.filter { url in
                    let ext = url.pathExtension.lowercased()
                    return ["jpg", "jpeg", "png", "heic", "mov", "mp4"].contains(ext)
                }
                
                // Sort by creation date (newest first)
                let sortedFiles = mediaFiles.sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    return date1 > date2
                }
                
                DispatchQueue.main.async {
                    self.mediaFiles = sortedFiles
                    self.collectionView.reloadData()
                    self.emptyLabel.isHidden = !sortedFiles.isEmpty
                }
            } catch {
                print("Error loading media: \(error)")
                DispatchQueue.main.async {
                    self.mediaFiles = []
                    self.collectionView.reloadData()
                    self.emptyLabel.isHidden = false
                }
            }
        }
    }
    
    @objc private func didTapClose() {
        dismiss(animated: true)
    }
    
    @objc private func didTapDeleteAll() {
        let alert = UIAlertController(
            title: "Delete All",
            message: "Are you sure you want to delete all photos and videos from \(currentStorageType == .internal ? "Internal" : "External") storage?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteAllMedia()
        })
        
        present(alert, animated: true)
    }
    
    private func deleteAllMedia() {
        for url in mediaFiles {
            try? FileManager.default.removeItem(at: url)
        }
        loadMedia()
    }
    
    private func deleteMedia(at index: Int) {
        let url = mediaFiles[index]
        do {
            try FileManager.default.removeItem(at: url)
            mediaFiles.remove(at: index)
            collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
            emptyLabel.isHidden = !mediaFiles.isEmpty
        } catch {
            print("Error deleting file: \(error)")
        }
    }
}

// MARK: - UICollectionViewDataSource
extension GalleryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaFiles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaCell", for: indexPath) as! MediaCell
        let url = mediaFiles[indexPath.item]
        cell.configure(with: url)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension GalleryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let url = mediaFiles[indexPath.item]
        let ext = url.pathExtension.lowercased()
        
        if ["mov", "mp4"].contains(ext) {
            // Play video
            let player = AVPlayer(url: url)
            let playerVC = AVPlayerViewController()
            playerVC.player = player
            present(playerVC, animated: true) {
                player.play()
            }
        } else {
            // Show photo
            let photoVC = PhotoViewerViewController(imageURL: url)
            photoVC.onDelete = { [weak self] in
                self?.deleteMedia(at: indexPath.item)
            }
            let navController = UINavigationController(rootViewController: photoVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension GalleryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 4) / 3
        return CGSize(width: width, height: width)
    }
}

// MARK: - MediaCell
class MediaCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let videoIcon = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        
        videoIcon.image = UIImage(systemName: "play.circle.fill")
        videoIcon.tintColor = .white
        videoIcon.isHidden = true
        contentView.addSubview(videoIcon)
        
        imageView.frame = contentView.bounds
        videoIcon.frame = CGRect(x: 8, y: 8, width: 30, height: 30)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = contentView.bounds
    }
    
    func configure(with url: URL) {
        let ext = url.pathExtension.lowercased()
        
        if ["mov", "mp4"].contains(ext) {
            // Video thumbnail
            videoIcon.isHidden = false
            loadVideoThumbnail(from: url)
        } else {
            // Photo
            videoIcon.isHidden = true
            if let image = UIImage(contentsOfFile: url.path) {
                imageView.image = image
            }
        }
    }
    
    private func loadVideoThumbnail(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            let time = CMTime(seconds: 0, preferredTimescale: 1)
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let thumbnail = UIImage(cgImage: cgImage)
                
                DispatchQueue.main.async {
                    self?.imageView.image = thumbnail
                }
            } catch {
                print("Error generating thumbnail: \(error)")
            }
        }
    }
}

// MARK: - PhotoViewerViewController
class PhotoViewerViewController: UIViewController {
    private let imageURL: URL
    private let imageView = UIImageView()
    private let scrollView = UIScrollView()
    var onDelete: (() -> Void)?
    
    init(imageURL: URL) {
        self.imageURL = imageURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(didTapClose)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .trash,
            target: self,
            action: #selector(didTapDelete)
        )
        navigationItem.rightBarButtonItem?.tintColor = .red
        
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        view.addSubview(scrollView)
        
        imageView.contentMode = .scaleAspectFit
        if let image = UIImage(contentsOfFile: imageURL.path) {
            imageView.image = image
        }
        scrollView.addSubview(imageView)
        
        scrollView.frame = view.bounds
        imageView.frame = view.bounds
    }
    
    @objc private func didTapClose() {
        dismiss(animated: true)
    }
    
    @objc private func didTapDelete() {
        let alert = UIAlertController(
            title: "Delete Photo",
            message: "Are you sure you want to delete this photo?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.onDelete?()
            self?.dismiss(animated: true)
        })
        
        present(alert, animated: true)
    }
}

extension PhotoViewerViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
