import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

// ── Layer 1 service definitions ───────────────────────────────────────────────
// Reflects the HelaService checklist items 5.1.1–5.1.10.
// Run once via the callable or via `firebase deploy && call seedServiceCatalog`.

interface ServiceSeed {
  id: string;
  name: string;
  nameSi: string;
  description: string;
  layer: 'category';
  pricingModel: 'hourly' | 'fixed' | 'packageBased';
  baseRatePerHour: number;
  defaultDurationHours: number;
  minDurationHours: number;
  maxDurationHours: number;
  minTier: 'green' | 'blue' | 'gold';
  requiredEquipment: string[];
  includedTasks: string[];
  isActive: boolean;
  isPopular: boolean;
  supportsRecurring: boolean;
}

const LAYER1_SERVICES: ServiceSeed[] = [
  {
    id: 'elder_companionship',
    name: 'Elder Companionship',
    nameSi: 'වැඩිහිටි සහකාරිත්වය',
    description: 'Friendly companionship, light activity assistance and social engagement for elderly household members.',
    layer: 'category',
    pricingModel: 'hourly',
    baseRatePerHour: 600,
    defaultDurationHours: 3,
    minDurationHours: 2,
    maxDurationHours: 8,
    minTier: 'blue',
    requiredEquipment: [],
    includedTasks: [
      'Conversation and companionship',
      'Light meal preparation',
      'Medication reminders',
      'Reading assistance',
      'Short walks within premises',
    ],
    isActive: true,
    isPopular: true,
    supportsRecurring: true,
  },
  {
    id: 'non_medical_immobilized_care',
    name: 'Non-Medical Immobilized Care',
    nameSi: 'අශක්ත රෝගී සත්කාර',
    description: 'Personal care assistance for immobilised or bedridden individuals — bathing, repositioning, feeding support.',
    layer: 'category',
    pricingModel: 'hourly',
    baseRatePerHour: 800,
    defaultDurationHours: 4,
    minDurationHours: 2,
    maxDurationHours: 8,
    minTier: 'gold',
    requiredEquipment: ['Gloves'],
    includedTasks: [
      'Bed bath or sponge bath',
      'Repositioning (pressure sore prevention)',
      'Feeding and hydration support',
      'Incontinence care',
      'Light range-of-motion exercises',
    ],
    isActive: true,
    isPopular: false,
    supportsRecurring: true,
  },
  {
    id: 'babysitting',
    name: 'Babysitting',
    nameSi: 'ළමා රැකවරණය',
    description: 'Safe and engaging childcare in your home for infants, toddlers and school-age children.',
    layer: 'category',
    pricingModel: 'hourly',
    baseRatePerHour: 650,
    defaultDurationHours: 3,
    minDurationHours: 2,
    maxDurationHours: 8,
    minTier: 'blue',
    requiredEquipment: [],
    includedTasks: [
      'Child supervision',
      'Playtime and activities',
      'Snack and meal preparation',
      'Nap-time routines',
      'Light tidying of play areas',
    ],
    isActive: true,
    isPopular: true,
    supportsRecurring: true,
  },
  {
    id: 'homework_support',
    name: 'Homework Support',
    nameSi: 'ගෙදර පාඩම් සහාය',
    description: 'Guided homework assistance for primary and secondary school students.',
    layer: 'category',
    pricingModel: 'hourly',
    baseRatePerHour: 500,
    defaultDurationHours: 2,
    minDurationHours: 1,
    maxDurationHours: 4,
    minTier: 'green',
    requiredEquipment: [],
    includedTasks: [
      'Homework guidance (not doing it for them)',
      'Reading and comprehension support',
      'Maths problem support',
      'School project assistance',
    ],
    isActive: true,
    isPopular: false,
    supportsRecurring: true,
  },
  {
    id: 'kitchen_helper',
    name: 'Kitchen Helper',
    nameSi: 'කුස්සිය සහායක',
    description: 'Meal preparation, cooking assistance and kitchen cleaning.',
    layer: 'category',
    pricingModel: 'hourly',
    baseRatePerHour: 450,
    defaultDurationHours: 2,
    minDurationHours: 2,
    maxDurationHours: 4,
    minTier: 'green',
    requiredEquipment: [],
    includedTasks: [
      'Ingredient preparation and chopping',
      'Cooking under household guidance',
      'Serving meals',
      'Washing dishes and pots',
      'Kitchen surface cleaning',
    ],
    isActive: true,
    isPopular: true,
    supportsRecurring: true,
  },
  {
    id: 'laundry_helper',
    name: 'Laundry Helper',
    nameSi: 'රෙදි සෝදන සේවය',
    description: 'Hand washing, machine washing, drying, ironing and folding laundry.',
    layer: 'category',
    pricingModel: 'hourly',
    baseRatePerHour: 400,
    defaultDurationHours: 2,
    minDurationHours: 2,
    maxDurationHours: 4,
    minTier: 'green',
    requiredEquipment: [],
    includedTasks: [
      'Sorting laundry by colour/fabric',
      'Machine or hand washing',
      'Drying and hanging',
      'Ironing (if requested)',
      'Folding and storing',
    ],
    isActive: true,
    isPopular: false,
    supportsRecurring: true,
  },
  {
    id: 'grocery_helper',
    name: 'Grocery Helper',
    nameSi: 'කඩේ ගිහිල්ල ගෙනෙන සේවය',
    description: 'Shopping assistance — accompany customer or complete the shop independently with a list.',
    layer: 'category',
    pricingModel: 'hourly',
    baseRatePerHour: 400,
    defaultDurationHours: 2,
    minDurationHours: 1,
    maxDurationHours: 3,
    minTier: 'green',
    requiredEquipment: [],
    includedTasks: [
      'Purchase items from provided list',
      'Carry and transport groceries',
      'Return change and receipt',
      'Unpack and store groceries at home',
    ],
    isActive: true,
    isPopular: false,
    supportsRecurring: false,
  },
  {
    id: 'house_sitting',
    name: 'House Sitting',
    nameSi: 'ගෙදර රැකවල් සේවය',
    description: 'Responsible supervision of your home while you are away — security check, plant watering, mail collection.',
    layer: 'category',
    pricingModel: 'fixed',
    baseRatePerHour: 500,
    defaultDurationHours: 8,
    minDurationHours: 4,
    maxDurationHours: 24,
    minTier: 'blue',
    requiredEquipment: [],
    includedTasks: [
      'Property security check (doors, windows)',
      'Plant watering',
      'Mail and parcel collection',
      'Feeding pets (if applicable)',
      'Emergency contact in case of issues',
    ],
    isActive: true,
    isPopular: false,
    supportsRecurring: false,
  },
  {
    id: 'pet_sitting',
    name: 'Pet Sitting',
    nameSi: 'සත්ව රැකවරණය',
    description: 'In-home care for your pets including feeding, walks and playtime.',
    layer: 'category',
    pricingModel: 'hourly',
    baseRatePerHour: 500,
    defaultDurationHours: 2,
    minDurationHours: 1,
    maxDurationHours: 8,
    minTier: 'blue',
    requiredEquipment: [],
    includedTasks: [
      'Feeding and fresh water',
      'Dog walking (on leash)',
      'Playtime and exercise',
      'Litter box cleaning (cats)',
      'Status update to owner',
    ],
    isActive: true,
    isPopular: false,
    supportsRecurring: true,
  },
  {
    id: 'hourly_household_support',
    name: 'Hourly Household Support',
    nameSi: 'පැයකාලීන ගෘහ සේවය',
    description: 'General household help — sweeping, mopping, surface cleaning, errands and light tasks.',
    layer: 'category',
    pricingModel: 'hourly',
    baseRatePerHour: 400,
    defaultDurationHours: 2,
    minDurationHours: 2,
    maxDurationHours: 8,
    minTier: 'green',
    requiredEquipment: [],
    includedTasks: [
      'Sweeping and mopping floors',
      'Dusting surfaces',
      'Bathroom cleaning',
      'Bin emptying',
      'Light general errands',
    ],
    isActive: true,
    isPopular: true,
    supportsRecurring: true,
  },
];

/**
 * Callable: seed all Layer 1 services into the service_catalog collection.
 * Idempotent — uses the service id as the document id so re-running is safe.
 * Restricted to admin users.
 */
export const seedServiceCatalog = functions.https.onCall(async (_data, context) => {
  if (!context.auth?.token?.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }

  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  for (const svc of LAYER1_SERVICES) {
    const ref = db.collection('service_catalog').doc(svc.id);
    batch.set(ref, { ...svc, createdAt: now, updatedAt: now }, { merge: true });
  }

  await batch.commit();
  return { seeded: LAYER1_SERVICES.length, ids: LAYER1_SERVICES.map(s => s.id) };
});
