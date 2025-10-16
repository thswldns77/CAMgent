import axios from "axios";
export class SearchYoutubeService {


  public async searchYoutube(params: { situation: string }): Promise<string> {
    const { situation } = params;
    const query = situation + " 잘 찍는 방법";

    const response = await axios.post("http://localhost:8000/search_youtube", { text: query });
    return response.data.url;

    
  }
}
