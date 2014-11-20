/*============================================================================
* ファイル名 : XxcsoInstallBaseExtractTermVORowImpl
* 概要説明   : 物件情報汎用検索画面／抽出条件取得ビュー行オブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-23 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * 抽出条件を取得するためのビュー行クラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallBaseExtractTermVORowImpl extends OAViewRowImpl 
{


  protected static final int EXTRACTPATTERN = 0;
  protected static final int EXTRACTTERMDEF = 1;
  protected static final int EXTRACTTERMTYPE = 2;
  protected static final int EXTRACTMETHODCODE = 3;
  protected static final int EXTRACTTERMTEXT = 4;
  protected static final int EXTRACTTERMNUMBER = 5;
  protected static final int EXTRACTTERMDATE = 6;
  protected static final int ENABLEFLAG = 7;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInstallBaseExtractTermVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractPattern
   */
  public String getExtractPattern()
  {
    return (String)getAttributeInternal(EXTRACTPATTERN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractPattern
   */
  public void setExtractPattern(String value)
  {
    setAttributeInternal(EXTRACTPATTERN, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractTermDef
   */
  public String getExtractTermDef()
  {
    return (String)getAttributeInternal(EXTRACTTERMDEF);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractTermDef
   */
  public void setExtractTermDef(String value)
  {
    setAttributeInternal(EXTRACTTERMDEF, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractTermType
   */
  public String getExtractTermType()
  {
    return (String)getAttributeInternal(EXTRACTTERMTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractTermType
   */
  public void setExtractTermType(String value)
  {
    setAttributeInternal(EXTRACTTERMTYPE, value);
  }







  /**
   * 
   * Gets the attribute value for the calculated attribute EnableFlag
   */
  public String getEnableFlag()
  {
    return (String)getAttributeInternal(ENABLEFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EnableFlag
   */
  public void setEnableFlag(String value)
  {
    setAttributeInternal(ENABLEFLAG, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EXTRACTPATTERN:
        return getExtractPattern();
      case EXTRACTTERMDEF:
        return getExtractTermDef();
      case EXTRACTTERMTYPE:
        return getExtractTermType();
      case EXTRACTMETHODCODE:
        return getExtractMethodCode();
      case EXTRACTTERMTEXT:
        return getExtractTermText();
      case EXTRACTTERMNUMBER:
        return getExtractTermNumber();
      case EXTRACTTERMDATE:
        return getExtractTermDate();
      case ENABLEFLAG:
        return getEnableFlag();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EXTRACTPATTERN:
        setExtractPattern((String)value);
        return;
      case EXTRACTTERMDEF:
        setExtractTermDef((String)value);
        return;
      case EXTRACTTERMTYPE:
        setExtractTermType((String)value);
        return;
      case EXTRACTMETHODCODE:
        setExtractMethodCode((String)value);
        return;
      case ENABLEFLAG:
        setEnableFlag((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractMethodCode
   */
  public String getExtractMethodCode()
  {
    return (String)getAttributeInternal(EXTRACTMETHODCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractMethodCode
   */
  public void setExtractMethodCode(String value)
  {
    setAttributeInternal(EXTRACTMETHODCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractTermText
   */
  public String getExtractTermText()
  {
    return (String)getAttributeInternal(EXTRACTTERMTEXT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractTermText
   */
  public void setExtractTermText(String value)
  {
    setAttributeInternal(EXTRACTTERMTEXT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractTermNumber
   */
  public Number getExtractTermNumber()
  {
    return (Number)getAttributeInternal(EXTRACTTERMNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractTermNumber
   */
  public void setExtractTermNumber(Number value)
  {
    setAttributeInternal(EXTRACTTERMNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractTermDate
   */
  public Date getExtractTermDate()
  {
    return (Date)getAttributeInternal(EXTRACTTERMDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractTermDate
   */
  public void setExtractTermDate(Date value)
  {
    setAttributeInternal(EXTRACTTERMDATE, value);
  }





}