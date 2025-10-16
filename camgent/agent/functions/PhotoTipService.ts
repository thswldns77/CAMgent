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

export class PhotoTipService {

    private embeddings: {
        index: number;
        text: string;
        embedding: number[];
      }[];

      constructor() {
        // embeddings 로드
        const raw = fs.readFileSync("camera_settings/situation_embeddings.json", "utf-8");
        this.embeddings = JSON.parse(raw);
      }
    

      public async getPhotoTip(params: { situation: string }): Promise<string> {
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
            너는 사진 전문가야. 사용자 요청에 맞춰 아래 string 형식으로 **아무 설명 없이** **오직 string만 출력**해.
          
            사용자 상황: "${situation}"
          
            설명이나 인사말은 포함하지 말고 상황에 대한 사진 팁을 간단하게 한 줄로, string만 출력해:
                    
            `;
          
          
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
          
          
                return parsed as string;
            }



      // bestIndex에 해당하는 행을 엑셀에서 읽음
        const workbook = xlsx.readFile("camera_settings/camera_settings.xlsx");
        const sheet = workbook.Sheets[workbook.SheetNames[0]];
        const rows = xlsx.utils.sheet_to_json<any>(sheet);
        const match = rows[bestIndex];      
          
        return match.note;
              
    }
}