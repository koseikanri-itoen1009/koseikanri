/*============================================================================
* ファイル名 : XxcsoCsvDownVOImpl
* 概要説明   : CSVダウンロードリージョン用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS及川領  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.BlobDomain;
/*******************************************************************************
 * CSVダウンロードリージョンを導出するためのビュー行クラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoCsvDownVORowImpl extends OAViewRowImpl 
{



  protected static final int FILENAME = 0;
  protected static final int FILEDATA = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoCsvDownVORowImpl()
  {
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case FILENAME:
        return getFileName();
      case FILEDATA:
        return getFileData();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case FILENAME:
        setFileName((String)value);
        return;
      case FILEDATA:
        setFileData((BlobDomain)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute FileName
   */
  public String getFileName()
  {
    return (String)getAttributeInternal(FILENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute FileName
   */
  public void setFileName(String value)
  {
    setAttributeInternal(FILENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute FileData
   */
  public BlobDomain getFileData()
  {
    return (BlobDomain)getAttributeInternal(FILEDATA);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute FileData
   */
  public void setFileData(BlobDomain value)
  {
    setAttributeInternal(FILEDATA, value);
  }
}