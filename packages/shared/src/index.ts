export * from "./calendar.js";
export * from "./homestead.js";
import type { CalendarState } from "./calendar.js";
import type { HomesteadState } from "./homestead.js";
export type AppearanceId =
  "male_default" | "male_nusantara" | "female_default" | "female_nusantara";
export type Role = "player" | "admin" | "owner";
export type Subject = "Biologi" | "Lingkungan" | "Matematika" | "Kimia";
export type Ability = "oxygen" | "bag" | "speed" | "net";
export type Stage = "dive" | "night" | "boss" | "done";
export interface Loot {
  fragmentId: string;
  stars: number;
  quantity: number;
}
export interface Progress {
  day: number;
  stage: Stage;
  tutorial: boolean;
  bossDefeated: boolean;
  missions: string[];
}
export interface Player {
  id: string;
  email: string;
  name: string;
  role: Role;
  status: "active" | "blocked";
  coins: number;
  inventory: Loot[];
  abilities: Record<Ability, number>;
  progress: Progress;
  version: number;
  authVersion: number;
  createdAt: string;
  updatedAt: string;
  calendar?: CalendarState;
  homestead?: HomesteadState;
  appearance?: AppearanceId;
  adventure?: { discoveries: string[]; puzzles: string[]; keyItems: string[] };
}
export interface Question {
  id: string;
  subject: Subject;
  phase: number;
  difficulty: number;
  prompt: string;
  options: string[];
  correctIndex: number;
  explanation: string;
  source: string;
  timeLimitMs: number;
  fragmentId: string;
}
export interface Fragment {
  id: string;
  name: string;
  subject: Subject;
  description: string;
  weight: number;
}
export interface Recipe {
  id: string;
  day: number;
  customer: string;
  complaint: string;
  solution: string;
  fragmentId: string;
  reward: number;
}
export interface AbilityDefinition {
  id: Ability;
  name: string;
  description: string;
  prices: number[];
  values: number[];
  unit: string;
}
export interface Balance {
  oxygenDrainPerSecond: number;
  wrongPenalty: number;
  starMultipliers: number[];
  bossHits: number;
  bossDamage: number;
}
export interface Catalog {
  questions: Question[];
  fragments: Fragment[];
  recipes: Recipe[];
  abilities: AbilityDefinition[];
  balance: Balance;
}
export interface ContentVersion {
  id: string;
  label: string;
  state: "draft" | "published" | "archived";
  catalog: Catalog;
  createdAt: string;
  publishedAt?: string;
}
export interface DiveView {
  id: string;
  mode: "dive" | "boss";
  contentId: string;
  oxygen: number;
  maxOxygen: number;
  weight: number;
  capacity: number;
  expiresAt: number;
  speed: number;
  net: number;
  hits: number;
  requiredHits: number;
  loot: Loot[];
  liveCatch?: { reef_seruni: number };
  position?: { x: number; y: number };
  targets: {
    id: string;
    fragmentId: string;
    subject: Subject;
    x: number;
    y: number;
    caught: boolean;
  }[];
  challenge?: {
    id: string;
    targetId: string;
    question: Omit<Question, "correctIndex" | "explanation" | "source">;
    startedAt: number;
    answered: boolean;
    result?: QuizResult;
  };
}
export interface QuizResult {
  correct: boolean;
  stars: number;
  explanation: string;
  source: string;
  answer: string;
}
export interface ShiftView {
  id: string;
  contentId: string;
  customers: Recipe[];
  served: string[];
  earnings: number;
}
export const freshProgress = (): Progress => ({
  day: 1,
  stage: "dive",
  tutorial: false,
  bossDefeated: false,
  missions: [],
});
export const freshAbilities = (): Record<Ability, number> => ({
  oxygen: 0,
  bag: 0,
  speed: 0,
  net: 0,
});
