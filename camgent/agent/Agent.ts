import dotenv from "dotenv";
import { Agentica } from "@agentica/core";
import OpenAI from "openai";
import typia from "typia";

dotenv.config();

import { CameraSettingService } from "./functions/CameraSettingService";
import { FeatureExplainService } from "./functions/FeatureExplainService";
import { ImageScoreService } from "./functions/ImageScoreService";
import { SearchYoutubeService } from "./functions/SearchYoutubeService";
import { ImageEnhanceService } from "./functions/ImageEnhanceService";
import { PhotoTipService } from "./functions/PhotoTipService";


export const agent = new Agentica({
    model: "chatgpt",
    vendor: {
      api: new OpenAI({ apiKey: process.env.OPENAI_API_KEY }),
      //model: "gpt-3.5-turbo",
      model: "gpt-4o-mini",
    },
    controllers: [
      {
        name: "Camera Setting Agent",
        protocol: "class",
        application: typia.llm.application<CameraSettingService, "chatgpt">(),
        execute: new CameraSettingService(),
      },
      {
        name: "App Feature Explainer",
        protocol: "class",
        application: typia.llm.application<FeatureExplainService, "chatgpt">(),
        execute: new FeatureExplainService(),
      },
      {
        name: "Image Score Evaluator",
        protocol: "class",
        application: typia.llm.application<ImageScoreService, "chatgpt">(),
        execute: new ImageScoreService(),
      },
      {
        name: "YouTube Finder",
        protocol: "class",
        application: typia.llm.application<SearchYoutubeService, "chatgpt">(),
        execute: new SearchYoutubeService(),
      },
      {
        name: "Image Enhancer",
        protocol: "class",
        application: typia.llm.application<ImageEnhanceService, "chatgpt">(),
        execute: new ImageEnhanceService(),
      },
      {
        name: "Photo Tip",
        protocol: "class",
        application: typia.llm.application<PhotoTipService, "chatgpt">(),
        execute: new PhotoTipService(),
      }
    ],
    
  });

  
  
  

