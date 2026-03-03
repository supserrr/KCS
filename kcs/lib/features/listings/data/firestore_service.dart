import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing.dart';
import '../../reviews/models/review.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _listings =>
      _firestore.collection('listings');

  Stream<List<Listing>> getListingsStream() {
    return _listings.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Listing>> getMyListings(String userId) {
    return _listings
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList());
  }

  Future<Listing?> getListingById(String id) async {
    final doc = await _listings.doc(id).get();
    if (doc.exists) {
      return Listing.fromFirestore(doc);
    }
    return null;
  }

  Future<void> createListing(Listing listing) async {
    final data = listing.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _listings.add(data);
  }

  Future<void> updateListing(String id, Listing listing) async {
    await _listings.doc(id).update(listing.toFirestore());
  }

  Future<void> deleteListing(String id) async {
    await _listings.doc(id).delete();
  }

  // reviews live under each listing so we can stream per-listing without loading everything
  CollectionReference<Map<String, dynamic>> _reviews(String listingId) =>
      _listings.doc(listingId).collection('reviews');

  Stream<List<Review>> getReviewsStream(String listingId) {
    return _reviews(listingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList());
  }

  Future<void> addReview(String listingId, Review review) async {
    await _reviews(listingId).add(review.toFirestore());
  }
}
