import java.io.File;
import java.io.PrintStream;
import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

public class Xml2Html
{
  public static void Transform(String xmlFileName, String xslFileName, String htmlFileName)
  {
    TransformerFactory tFac;
    try
    {
      tFac = TransformerFactory.newInstance();
      Source xslSource = new StreamSource(xslFileName);
      Transformer t = tFac.newTransformer(xslSource);
      File xmlFile = new File(xmlFileName);
      File htmlFile = new File(htmlFileName);
      Source source = new StreamSource(xmlFile);
      Result result = new StreamResult(htmlFile);
      System.out.println(result.toString());
      t.transform(source, result);
    } catch (TransformerConfigurationException e) {
      e.printStackTrace();
    } catch (TransformerException e) {
      e.printStackTrace();
    }
  }

  public static void main(String[] args)
  {
    String xmlFileName = args[0] +"/summary.xml";
    String xslFileName = args[0] +"/app.xsl";
    String htmlFileName = args[0] +"/summary.html";
    Transform(xmlFileName, xslFileName, htmlFileName);
  }
}