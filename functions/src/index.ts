import {setGlobalOptions} from "firebase-functions";
import {onRequest} from "firebase-functions/v2/https";
import axios from "axios";
import * as logger from "firebase-functions/logger";

setGlobalOptions({
  maxInstances: 10,
});
const GOOGLE_MAPS_API_KEY = "AIzaSyCeH7N4mIZsgqfseaNlT9IVFEiFszVaZBQ";
interface PlacePhoto {
  photo_reference: string;
}
interface Place {
  place_id?: string;
  name?: string;
  rating?: number;
  user_ratings_total?: number;
  price_level?: number;
  types?: string[];
  photos?: PlacePhoto[];
  opening_hours?: {
    open_now?: boolean;
  };
  geometry?: {
    location?: {
      lat: number;
      lng: number;
    };
  };
}
export const getRestaurants = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  try {
    const lng = req.query.lng;
    const lat = req.query.lat;
    if (!lat || !lng) {
      res.status(400).json({error: "Missing latitude or longitude"});
      return;
    }
    const response = await axios.get(
      "https://maps.googleapis.com/maps/api/place/nearbysearch/json",
      {
        params: {
          location: `${lat},${lng}`,
          radius: 2000,
          type: "restaurant",
          keyword: "restaurant",
          language: "zh-TW",
          key: GOOGLE_MAPS_API_KEY,
        },
      }
    );
    // res.json(response.data);
    const results = (response.data.results || []).map((place: Place) => {
      const photoRef = place.photos?.[0]?.photo_reference;
      const photoUrl = photoRef != null ? `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=${encodeURIComponent(photoRef)}&key=${GOOGLE_MAPS_API_KEY}` : null;
      return {
        placeId: place.place_id ?? "",
        name: place.name ?? "Unknown",
        rating: place.rating ?? 0,
        userRatingsTotal: place.user_ratings_total ?? 0,
        priceLevel: place.price_level ?? null,
        location: place.geometry?.location ?? null,
        photoUrl: photoUrl,
        types: place.types ?? [],
        openNow: place.opening_hours?.open_now ?? null,
      };
    });
    res.status(200).json({
      status: "OK",
      results,
    });
  } catch (error) {
    logger.error(error);
    res.status(500).json({error: "Google API failed"});
  }
});
