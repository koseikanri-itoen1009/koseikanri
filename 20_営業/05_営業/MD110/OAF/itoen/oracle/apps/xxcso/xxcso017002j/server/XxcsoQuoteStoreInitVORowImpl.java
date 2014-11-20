/*============================================================================
* ファイル名 : XxcsoQuoteStoreInitVORowImpl
* 概要説明   : 初期化用ビュー行クラス
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
import oracle.jbo.domain.Date;
/*******************************************************************************
 * 初期化検索するためのビュー行クラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteStoreInitVORowImpl extends OAViewRowImpl 
{


  protected static final int EMPLOYEENUMBER = 0;
  protected static final int FULLNAME = 1;
  protected static final int WORKBASECODE = 2;
  protected static final int WORKBASENAME = 3;
  protected static final int CURRENTDATE = 4;
  protected static final int REFQUOTENUMBERRENDER = 5;
  protected static final int REFQUOTENUMBERVIEWRENDER = 6;
  protected static final int COPYCREATEBUTTONRENDER = 7;
  protected static final int INVALIDITYBUTTONRENDER = 8;
  protected static final int APPLICABLEBUTTONRENDER = 9;
  protected static final int REVISIONBUTTONRENDER = 10;
  protected static final int FIXEDBUTTONRENDER = 11;
  protected static final int QUOTESHEETPRINTBUTTONRENDER = 12;
  protected static final int CSVCREATEBUTTONRENDER = 13;
  protected static final int DELIVPRICETAXTYPERENDER = 14;
  protected static final int DELIVPRICETAXTYPEVIEWRENDER = 15;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteStoreInitVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EmployeeNumber
   */
  public String getEmployeeNumber()
  {
    return (String)getAttributeInternal(EMPLOYEENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EmployeeNumber
   */
  public void setEmployeeNumber(String value)
  {
    setAttributeInternal(EMPLOYEENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute FullName
   */
  public String getFullName()
  {
    return (String)getAttributeInternal(FULLNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute FullName
   */
  public void setFullName(String value)
  {
    setAttributeInternal(FULLNAME, value);
  }





  /**
   * 
   * Gets the attribute value for the calculated attribute CurrentDate
   */
  public Date getCurrentDate()
  {
    return (Date)getAttributeInternal(CURRENTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CurrentDate
   */
  public void setCurrentDate(Date value)
  {
    setAttributeInternal(CURRENTDATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case FULLNAME:
        return getFullName();
      case WORKBASECODE:
        return getWorkBaseCode();
      case WORKBASENAME:
        return getWorkBaseName();
      case CURRENTDATE:
        return getCurrentDate();
      case REFQUOTENUMBERRENDER:
        return getRefQuoteNumberRender();
      case REFQUOTENUMBERVIEWRENDER:
        return getRefQuoteNumberViewRender();
      case COPYCREATEBUTTONRENDER:
        return getCopyCreateButtonRender();
      case INVALIDITYBUTTONRENDER:
        return getInvalidityButtonRender();
      case APPLICABLEBUTTONRENDER:
        return getApplicableButtonRender();
      case REVISIONBUTTONRENDER:
        return getRevisionButtonRender();
      case FIXEDBUTTONRENDER:
        return getFixedButtonRender();
      case QUOTESHEETPRINTBUTTONRENDER:
        return getQuoteSheetPrintButtonRender();
      case CSVCREATEBUTTONRENDER:
        return getCsvCreateButtonRender();
      case DELIVPRICETAXTYPERENDER:
        return getDelivPriceTaxTypeRender();
      case DELIVPRICETAXTYPEVIEWRENDER:
        return getDelivPriceTaxTypeViewRender();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EMPLOYEENUMBER:
        setEmployeeNumber((String)value);
        return;
      case FULLNAME:
        setFullName((String)value);
        return;
      case WORKBASECODE:
        setWorkBaseCode((String)value);
        return;
      case WORKBASENAME:
        setWorkBaseName((String)value);
        return;
      case CURRENTDATE:
        setCurrentDate((Date)value);
        return;
      case REFQUOTENUMBERRENDER:
        setRefQuoteNumberRender((Boolean)value);
        return;
      case REFQUOTENUMBERVIEWRENDER:
        setRefQuoteNumberViewRender((Boolean)value);
        return;
      case COPYCREATEBUTTONRENDER:
        setCopyCreateButtonRender((Boolean)value);
        return;
      case INVALIDITYBUTTONRENDER:
        setInvalidityButtonRender((Boolean)value);
        return;
      case APPLICABLEBUTTONRENDER:
        setApplicableButtonRender((Boolean)value);
        return;
      case REVISIONBUTTONRENDER:
        setRevisionButtonRender((Boolean)value);
        return;
      case FIXEDBUTTONRENDER:
        setFixedButtonRender((Boolean)value);
        return;
      case QUOTESHEETPRINTBUTTONRENDER:
        setQuoteSheetPrintButtonRender((Boolean)value);
        return;
      case CSVCREATEBUTTONRENDER:
        setCsvCreateButtonRender((Boolean)value);
        return;
      case DELIVPRICETAXTYPERENDER:
        setDelivPriceTaxTypeRender((Boolean)value);
        return;
      case DELIVPRICETAXTYPEVIEWRENDER:
        setDelivPriceTaxTypeViewRender((Boolean)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RefQuoteNumberRender
   */
  public Boolean getRefQuoteNumberRender()
  {
    return (Boolean)getAttributeInternal(REFQUOTENUMBERRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RefQuoteNumberRender
   */
  public void setRefQuoteNumberRender(Boolean value)
  {
    setAttributeInternal(REFQUOTENUMBERRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RefQuoteNumberViewRender
   */
  public Boolean getRefQuoteNumberViewRender()
  {
    return (Boolean)getAttributeInternal(REFQUOTENUMBERVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RefQuoteNumberViewRender
   */
  public void setRefQuoteNumberViewRender(Boolean value)
  {
    setAttributeInternal(REFQUOTENUMBERVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CopyCreateButtonRender
   */
  public Boolean getCopyCreateButtonRender()
  {
    return (Boolean)getAttributeInternal(COPYCREATEBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CopyCreateButtonRender
   */
  public void setCopyCreateButtonRender(Boolean value)
  {
    setAttributeInternal(COPYCREATEBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InvalidityButtonRender
   */
  public Boolean getInvalidityButtonRender()
  {
    return (Boolean)getAttributeInternal(INVALIDITYBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InvalidityButtonRender
   */
  public void setInvalidityButtonRender(Boolean value)
  {
    setAttributeInternal(INVALIDITYBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApplicableButtonRender
   */
  public Boolean getApplicableButtonRender()
  {
    return (Boolean)getAttributeInternal(APPLICABLEBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApplicableButtonRender
   */
  public void setApplicableButtonRender(Boolean value)
  {
    setAttributeInternal(APPLICABLEBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RevisionButtonRender
   */
  public Boolean getRevisionButtonRender()
  {
    return (Boolean)getAttributeInternal(REVISIONBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RevisionButtonRender
   */
  public void setRevisionButtonRender(Boolean value)
  {
    setAttributeInternal(REVISIONBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute FixedButtonRender
   */
  public Boolean getFixedButtonRender()
  {
    return (Boolean)getAttributeInternal(FIXEDBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute FixedButtonRender
   */
  public void setFixedButtonRender(Boolean value)
  {
    setAttributeInternal(FIXEDBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteSheetPrintButtonRender
   */
  public Boolean getQuoteSheetPrintButtonRender()
  {
    return (Boolean)getAttributeInternal(QUOTESHEETPRINTBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteSheetPrintButtonRender
   */
  public void setQuoteSheetPrintButtonRender(Boolean value)
  {
    setAttributeInternal(QUOTESHEETPRINTBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CsvCreateButtonRender
   */
  public Boolean getCsvCreateButtonRender()
  {
    return (Boolean)getAttributeInternal(CSVCREATEBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CsvCreateButtonRender
   */
  public void setCsvCreateButtonRender(Boolean value)
  {
    setAttributeInternal(CSVCREATEBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute WorkBaseCode
   */
  public String getWorkBaseCode()
  {
    return (String)getAttributeInternal(WORKBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute WorkBaseCode
   */
  public void setWorkBaseCode(String value)
  {
    setAttributeInternal(WORKBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute WorkBaseName
   */
  public String getWorkBaseName()
  {
    return (String)getAttributeInternal(WORKBASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute WorkBaseName
   */
  public void setWorkBaseName(String value)
  {
    setAttributeInternal(WORKBASENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DelivPriceTaxTypeRender
   */
  public Boolean getDelivPriceTaxTypeRender()
  {
    return (Boolean)getAttributeInternal(DELIVPRICETAXTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DelivPriceTaxTypeRender
   */
  public void setDelivPriceTaxTypeRender(Boolean value)
  {
    setAttributeInternal(DELIVPRICETAXTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DelivPriceTaxTypeViewRender
   */
  public Boolean getDelivPriceTaxTypeViewRender()
  {
    return (Boolean)getAttributeInternal(DELIVPRICETAXTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DelivPriceTaxTypeViewRender
   */
  public void setDelivPriceTaxTypeViewRender(Boolean value)
  {
    setAttributeInternal(DELIVPRICETAXTYPEVIEWRENDER, value);
  }



}