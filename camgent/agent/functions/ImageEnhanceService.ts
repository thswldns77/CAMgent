import axios from "axios";

export class ImageEnhanceService {
  
  public async enhanceImage(params: { imagePath: string }): Promise<string> {
    
    const response = await axios.post("http://localhost:8000/enhance", {
      image_path: params.imagePath, 
    });
    

    return response.data.output_path;
    
    
  }

}
