# Plan: Populate geocoding restriction fields from Mapbox place search

## Context
When a user selects a place from the Mapbox search in RestrictionsSection, only the `place` field in `other_filters` is populated. The Mapbox v6 forward geocoding API returns context data (region, postcode, district, locality, neighborhood) that should be used to auto-populate all 6 geocoding restriction fields.

## File to modify
`client/src/components/citySimple/sections/RestrictionsSection.vue`

## Changes

### 0. Add `myClaudeMd` to `.gitignore`
Append `myClaudeMd` to `.gitignore` so personal Claude instruction files aren't committed.

### 1. Update `types` in Mapbox API URL (line 210)
Change `types=place,locality,district` to `types=place,locality,district,postcode,neighborhood` so the API returns postcode and neighborhood features, making those fields available in results.

### 2. Extract context fields in `searchPlaces` (line 215-219)
Add context fields from `f.properties.context` to each result object:

```typescript
searchResults.value = features.map((f: any) => ({
  id: f.id || f.properties?.mapbox_id || Math.random().toString(),
  name: f.properties?.name || f.properties?.full_address || query,
  fullName: f.properties?.full_address || f.properties?.place_formatted || f.properties?.name || '',
  place: f.properties?.context?.place?.name || f.properties?.name || '',
  region: f.properties?.context?.region?.name || '',
  postcode: f.properties?.context?.postcode?.name || '',
  district: f.properties?.context?.district?.name || '',
  locality: f.properties?.context?.locality?.name || '',
  neighborhood: f.properties?.context?.neighborhood?.name || '',
}));
```

Note: For `place`, if the feature itself IS a place type, `context.place` may not exist — use `properties.name` as fallback.

### 3. Update `selectPlace` (line 242-248) to populate all fields

```typescript
function selectPlace(result: any) {
  console.log('selectPlace', result);
  if (cityDetailsForm.value?.geocodingRestrictions) {
    if (!cityDetailsForm.value.geocodingRestrictions.other_filters) {
      cityDetailsForm.value.geocodingRestrictions.other_filters = {};
    }
    const filters = cityDetailsForm.value.geocodingRestrictions.other_filters;
    filters.place = result.place || result.name || '';
    filters.region = result.region || '';
    filters.postcode = result.postcode || '';
    filters.district = result.district || '';
    filters.locality = result.locality || '';
    filters.neighborhood = result.neighborhood || '';
  }
  searchQuery.value = '';
  searchResults.value = [];
  showDropdown.value = false;
}
```

### 4. Update `clearPlace` (line 250-252) to clear all fields

```typescript
function clearPlace() {
  if (cityDetailsForm.value?.geocodingRestrictions?.other_filters) {
    const filters = cityDetailsForm.value.geocodingRestrictions.other_filters;
    filters.place = '';
    filters.region = '';
    filters.postcode = '';
    filters.district = '';
    filters.locality = '';
    filters.neighborhood = '';
  }
}
```

### 5. No change needed to `placeFilter`
Keep `placeFilter` computed as-is — it reads/writes `other_filters.place` and is used for the display tag in the template. Since `selectPlace` now writes to `other_filters.place` directly, `placeFilter` will reactively reflect the correct value.

## Verification
- Run `npm run type-check` from `/client`
- In the app, search for a place (e.g. "Bondi Beach") and select it
- Check that `place`, `region`, `postcode`, `district`, `locality`, `neighborhood` fields are populated in the form
- Click the clear button — verify all 6 fields are cleared
