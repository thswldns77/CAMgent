import xlsx from "xlsx";
import axios from "axios";
import fs from "fs";
import OpenAI from "openai";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY!,
});


// cosine similarity
function cosineSimilarity(vecA: number[], vecB: number[]): number {
    let dot = 0, normA = 0, normB = 0;
    for (let i = 0; i < vecA.length; i++) {
      dot += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }
    return dot / (Math.sqrt(normA) * Math.sqrt(normB));
  }

interface CameraSetting {
    situation: string;
    SENSOR_SENSITIVITY: number;
    SENSOR_EXPOSURE_TIME: number;
    COLOR_CORRECTION_MODE: string;
    COLOR_CORRECTION_GAINS: number[];
    LENS_FOCUS_DISTANCE: number;
    CONTROL_AE_EXPOSURE_COMPENSATION: number;
    CONTROL_SCENE_MODE: string;
    CONTROL_AWB_LOCK: boolean;
    CONTROL_AE_LOCK: boolean;
    FLASH_MODE: string;
    CONTROL_AF_REGIONS: string;
    CONTROL_AE_REGIONS: string;
    CONTROL_EFFECT_MODE: string;
    NOISE_REDUCTION_MODE: string;
    TONEMAP_MODE: string;
    CONTROL_AE_ANTIBANDING_MODE: string;
    CONTROL_AE_TARGET_FPS_RANGE: number[];
    note: string;
  }


export class CameraSettingService {

    private embeddings: {
        index: number;
        text: string;
        embedding: number[];
      }[];

    private defaultSetting: CameraSetting = {
        situation: "default",
        SENSOR_SENSITIVITY: 400,
        SENSOR_EXPOSURE_TIME: 1_000_000_000,             // 1초
        COLOR_CORRECTION_MODE: "AUTO",
        COLOR_CORRECTION_GAINS: [1.0, 1.0, 1.0, 1.0],
        LENS_FOCUS_DISTANCE: 1.0,
        CONTROL_AE_EXPOSURE_COMPENSATION: 0,
        CONTROL_SCENE_MODE: "AUTO",
        CONTROL_AWB_LOCK: false,
        CONTROL_AE_LOCK: false,
        FLASH_MODE: "AUTO",
        CONTROL_AF_REGIONS: "center",
        CONTROL_AE_REGIONS: "center",
        CONTROL_EFFECT_MODE: "OFF",
        NOISE_REDUCTION_MODE: "FAST",
        TONEMAP_MODE: "GAMMA_VALUE",
        CONTROL_AE_ANTIBANDING_MODE: "AUTO",
        CONTROL_AE_TARGET_FPS_RANGE: [15, 30],
        note: "기본 프리셋"
      };

      constructor() {
        // embeddings 로드
        const raw = fs.readFileSync("camera_settings/situation_embeddings.json", "utf-8");
        this.embeddings = JSON.parse(raw);
      }
    

      public async getCameraSetting(params: { situation: string }): Promise<CameraSetting> {
        const { situation } = params;

        // 사용자 상황을 임베딩으로
        const response = await axios.post("http://localhost:8000/embed", { text: situation });
        const queryEmbedding = response.data.embedding;

        // 가장 가까운 것 찾기
        let bestScore = -Infinity;
        let bestIndex = -1;

        for (const item of this.embeddings) {
            const score = cosineSimilarity(queryEmbedding, item.embedding);
            if (score > bestScore) {
              bestScore = score;
              bestIndex = item.index;
            }
            
        }
        console.log(bestScore)

        // GPT로 처리 (유사도 낮을 경우)
        if (bestScore < 0.53) {
          console.log("GPT로 카메라 설정 생성 시작");

          const prompt = `
          너는 사진 전문가야. 사용자 요청에 맞춰 아래 JSON 형식으로 **아무 설명 없이** **오직 JSON만 출력**해.

          사용자 상황: "${situation}"

          반드시 이 형식과 일치해야 하며, 설명이나 인사말은 포함하지 마. JSON만 출력해:
          
          {
            "situation": "설명",
            "SENSOR_SENSITIVITY": 800,
            "SENSOR_EXPOSURE_TIME": 100000000,
            "COLOR_CORRECTION_MODE": "AUTO",
            "COLOR_CORRECTION_GAINS": [1.2, 1.0, 1.0, 1.1],
            "LENS_FOCUS_DISTANCE": 1.0,
            "CONTROL_AE_EXPOSURE_COMPENSATION": 0,
            "CONTROL_SCENE_MODE": "LANDSCAPE",
            "CONTROL_AWB_LOCK": false,
            "CONTROL_AE_LOCK": false,
            "FLASH_MODE": "OFF",
            "CONTROL_AF_REGIONS": "center",
            "CONTROL_AE_REGIONS": "center",
            "CONTROL_EFFECT_MODE": "OFF",
            "NOISE_REDUCTION_MODE": "HIGH_QUALITY",
            "TONEMAP_MODE": "GAMMA_VALUE",
            "CONTROL_AE_ANTIBANDING_MODE": "AUTO",
            "CONTROL_AE_TARGET_FPS_RANGE": [24, 30],
            "note": "설정 이유"
          }`;


          const completion = await openai.chat.completions.create({
            model: "gpt-4o-mini",
            messages: [
              { role: "user", content: prompt }
            ],
          });
          

          const gptReply = completion.choices[0].message.content;
          if (!gptReply) {
            throw new Error("GPT 응답이 비어있습니다.");
          }
          const parsed = JSON.parse(gptReply);


          return parsed as CameraSetting;
        }




        // bestIndex에 해당하는 행을 엑셀에서 읽음
        const workbook = xlsx.readFile("camera_settings/camera_settings.xlsx");
        const sheet = workbook.Sheets[workbook.SheetNames[0]];
        const rows = xlsx.utils.sheet_to_json<any>(sheet);
        const match = rows[bestIndex];
       

        if (!match || bestIndex === 0) return this.defaultSetting;

        
    
        return {
          situation: match.situation_korean,
          SENSOR_SENSITIVITY: Number(match.SENSOR_SENSITIVITY),
          SENSOR_EXPOSURE_TIME: this.exposureToNanoseconds(match.SENSOR_EXPOSURE_TIME),
          COLOR_CORRECTION_MODE: match.COLOR_CORRECTION_MODE,
          COLOR_CORRECTION_GAINS: match.COLOR_CORRECTION_GAINS.split(",").map(Number),
          LENS_FOCUS_DISTANCE: match.LENS_FOCUS_DISTANCE === "infinity" ? 0.0 : Number(match.LENS_FOCUS_DISTANCE),
          CONTROL_AE_EXPOSURE_COMPENSATION: Number(match.CONTROL_AE_EXPOSURE_COMPENSATION),
          CONTROL_SCENE_MODE: match.CONTROL_SCENE_MODE,
          CONTROL_AWB_LOCK: this.parseBool(match.CONTROL_AWB_LOCK),
          CONTROL_AE_LOCK: this.parseBool(match.CONTROL_AE_LOCK),
          FLASH_MODE: match.FLASH_MODE,
          CONTROL_AF_REGIONS: match.CONTROL_AF_REGIONS,
          CONTROL_AE_REGIONS: match.CONTROL_AE_REGIONS,
          CONTROL_EFFECT_MODE: match.CONTROL_EFFECT_MODE,
          NOISE_REDUCTION_MODE: match.NOISE_REDUCTION_MODE,
          TONEMAP_MODE: match.TONEMAP_MODE,
          CONTROL_AE_ANTIBANDING_MODE: match.CONTROL_AE_ANTIBANDING_MODE,
          CONTROL_AE_TARGET_FPS_RANGE: this.parseFps(match.CONTROL_AE_TARGET_FPS_RANGE),
          note: match.note,
        };
      }
    

      
      /**
       * 15s → 15000000000ns 변환
       */
      private exposureToNanoseconds(str: string): number {
        if (str.endsWith("s")) {
          return Number(str.replace("s", "")) * 1_000_000_000;
        }
        return 0;
      }
    
      /**
       * 문자열 true/false → boolean
       */
      private parseBool(val: string) {
        return String(val).toLowerCase() === "true";
      }
    
      /**
       * 15~30 → [15,30]
       */
      private parseFps(str: string): number[] {
        if (str.includes("~")) {
          return str.split("~").map(Number);
        }
        const fixed = Number(str);
        return [fixed];
      }
}
  