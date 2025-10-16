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
exports.ImageScoreService = void 0;
const axios_1 = __importDefault(require("axios"));
const form_data_1 = __importDefault(require("form-data"));
const fs_1 = __importDefault(require("fs"));
class ImageScoreService {
    analyzeImageScore(params) {
        return __awaiter(this, void 0, void 0, function* () {
            // ✅ 파라미터 값 출력
            console.log("[ImageScore] params:", params);
            console.log("[ImageScore] params.imagePath:", params.imagePath);
            const form = new form_data_1.default();
            form.append("image", fs_1.default.createReadStream(params.imagePath));
            const response = yield axios_1.default.post("http://127.0.0.1:8000/analyze", form, {
                headers: form.getHeaders(),
            });
            const score = response.data.score;
            return `이 이미지의 미적 품질 점수는 ${score}점입니다.`;
        });
    }
}
exports.ImageScoreService = ImageScoreService;
