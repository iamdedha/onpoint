class NewsModel {
  final String head;
  final String newsUrl;
  final String image;
  final String desc;

  NewsModel({
    required this.head,
    required this.newsUrl,
    required this.image,
    required this.desc,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      head: json['head'],
      newsUrl: json['news_url'],
      image: json['img_url'], // updated key from "image" to "img_url"
      desc: json['desc'] ?? '',
    );
  }
}
