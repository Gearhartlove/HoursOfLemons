# HoursOfLemons

The intention of this project is to create a **vertical slice** of a RAG based AI Agent that answer's question from a pdf, reinforcing with images and referenced page numbers.

The subject of this project is 24 Hours of Lemons, described as "An endurance car racing series on dedicated road courses for $500 cars.".

## What problem you decided to tackle and why
24 Hours of Lemons has many resources on their site, including checkboxes, drop-down lists, and more. For this prototype I'll be tackling a PDF with technical pictures and descriptive instructions on various pages. This prototype will illustrate how to interact with any technical PDF 24 Hours of Lemons has. The PDFs specifically can be an arbitrary length, containing dozens of pictures, and can even ultimately intimidate and slowdown anyone looking to glean useful and accurate information. This Virtual Assistant seeks to ease these problems and help users search through PDFs more effectively by supplying answers, images, and page numbers relevant to the user inquiry. An added benefit of using the Virtual Assistant is it's ability to tie together queries across topics; if a customer asks a question about a roll cage, the Virtual Assistant is able to identify multiple sections of the document containing useful information. Notably, this extends beyond the historically effective strategy of skimming headers for useful reference points.

## How did I approach this problem?
I approached this prototype with a **data first approach**. In order to deliver an accurate and reference-friendly Virtual-Assistant, I needed to first extract useful information from the PDF. The PDF in question is: https://24hoursoflemons.com/wp-content/themes/lemons/assets/images/how-to-not-fail-lemons-tech-inspection.pdf . 

I used a popular python library called `pymupdf` to extract the text and images from the pdf in question. The structure of the extracted data can be seen in `data/extracted/`; it's comprised of a file of images labeled `page_{page_number}_image_{number}` with an extension of `.png` or `.jpg`. The text is all in a single file called `extracted_metadata.json`. Each `page` has a `page_number`, `text`, as well as `images`, and an `image_count`. Notably, each image in `images` references an extracted image; this is powerful because the Virtual Assistant can now compartmentalize each page to what text and images it contains. We'll see this features importance when prompting a response.

After solving the data extraction, I set out to query my yet-to-exist virtual assistant. Here are a number of design decisions and implementation details: 
- **GenServer as a foundation**: I settled on a GenServer because I wanted the capability to change different components at runtime if need be. For example, what happens if a new version of the dataset exists, I would want the Virtual Assistant to be able to reference the new dataset without needing a reset, promoting zero-downtime practices. To facilitate this, I store important keys like the `:dataset_path` path as an atom I could update in the future if need be. GenServers also offer an easy extension to store conversation state or anything else if need be, over the course of the Virtual Assistant's lifetime.
- **Queryable, not conversational**: To promote simplicity, I opted for a single query approach. The user is not having a conversation with a Virtual Assistant, instead they will be issuing specific queries for the Virtual Assisntant. 
- **Simple interface**: the only actions the user can take are `query` or `start_link`. For my use case, I want to start up my Virtual Assistant and start asking questions, these two functions facilitate these goals nicely.
- **Only support querying OpenAI**: in general, I'm a big believer in being "llm agnostic" - aka not needing to rely on any specific provider, however for this project I opted to write a *small* amount of boiler plate to query off to OpenAI to generate a simple response. I'm not using tool use or reasoning or previous_response_ids or anything else like that. To me, this was not the interesting part of this Virtual Assistant, so I settled with a good enough system prompt with embedded dataset. 



