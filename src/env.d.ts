// src/env.d.ts
interface Window {
    env: {
      DUPES_JSON_FROM_DOCKER: string;
      API_KEY_FROM_DOCKER: string;
      IMMICH_URL: string;
      IMMICH_DISPLAY_URL: string;
    };
  }
  