import axios from "axios";
import FormData from "form-data";
import fs from "fs";

export class ImageScoreService {

    public async analyzeImageScore(params: { imagePath: string }): Promise<string> {
            // ✅ 파라미터 값 출력
        console.log("[ImageScore] params:", params);
        console.log("[ImageScore] params.imagePath:", params.imagePath);
        const form = new FormData();
        form.append("image", fs.createReadStream(params.imagePath));
        const response = await axios.post("http://127.0.0.1:8000/analyze", form, {
            headers: form.getHeaders(),
        });

        const score = response.data.score;
        return `이 이미지의 미적 품질 점수는 ${score}점입니다.`;
    }
}
