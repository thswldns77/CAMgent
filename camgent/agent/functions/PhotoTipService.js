"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PhotoTipService = void 0;
const xlsx_1 = __importDefault(require("xlsx"));
const axios_1 = __importDefault(require("axios"));
const fs_1 = __importDefault(require("fs"));
const openai_1 = __importDefault(require("openai"));
const openai = new openai_1.default({
    apiKey: process.env.OPENAI_API_KEY,
});
// cosine similarity
function cosineSimilarity(vecA, vecB) {
    let dot = 0, normA = 0, normB = 0;
    for (let i = 0; i < vecA.length; i++) {
        dot += vecA[i] * vecB[i];
        normA += vecA[i] * vecA[i];
        normB += vecB[i] * vecB[i];
    }
    return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}
class PhotoTipService {
    constructor() {
        // embeddings 로드
        const raw = fs_1.default.readFileSync("camera_settings/situation_embeddings.json", "utf-8");
        this.embeddings = JSON.parse(raw);
    }
    getPhotoTip(params) {
        return __awaiter(this, void 0, void 0, function* () {
            const { situation } = params;
            // 사용자 상황을 임베딩으로
            const response = yield axios_1.default.post("http://localhost:8000/embed", { text: situation });
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
            console.log(bestScore);
            // GPT로 처리 (유사도 낮을 경우)
            if (bestScore < 0.53) {
                console.log("GPT로 카메라 설정 생성 시작");
                const prompt = `
            너는 사진 전문가야. 사용자 요청에 맞춰 아래 string 형식으로 **아무 설명 없이** **오직 string만 출력**해.
          
            사용자 상황: "${situation}"
          
            설명이나 인사말은 포함하지 말고 상황에 대한 사진 팁을 간단하게 한 줄로, string만 출력해:
                    
            `;
                const completion = yield openai.chat.completions.create({
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
                return parsed;
            }
            // bestIndex에 해당하는 행을 엑셀에서 읽음
            const workbook = xlsx_1.default.readFile("camera_settings/camera_settings.xlsx");
            const sheet = workbook.Sheets[workbook.SheetNames[0]];
            const rows = xlsx_1.default.utils.sheet_to_json(sheet);
            const match = rows[bestIndex];
            return match.note;
        });
    }
}
exports.PhotoTipService = PhotoTipService;
