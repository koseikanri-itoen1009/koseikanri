/*============================================================================
* ファイル名 : XxcsoSalesPlanBulkRegistInitVOImpl
* 概要説明   : 売上計画(複数顧客)　対象指定リージョンビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS朴邦彦　  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019002j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * 売上計画(複数顧客)　対象指定リージョンビュー行クラス
 * @author  SCS朴邦彦
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesPlanBulkRegistInitVORowImpl extends OAViewRowImpl 
{


  protected static final int EMPLOYEENUMBER = 0;
  protected static final int FULLNAME = 1;
  protected static final int REFLECTMETHOD = 2;
  protected static final int TARGETYEAR = 3;
  protected static final int TARGETMONTH = 4;
  protected static final int TARGETYEARMONTH = 5;
  protected static final int NEXTYEARMONTH = 6;
  protected static final int BASECODE = 7;
  protected static final int RESULTRENDER = 8;
  protected static final int READONLYFLG = 9;
  protected static final int MYEMPLOYEENUMBER = 10;
  protected static final int MYFULLNAME = 11;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesPlanBulkRegistInitVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TargetYear
   */
  public String getTargetYear()
  {
    return (String)getAttributeInternal(TARGETYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TargetYear
   */
  public void setTargetYear(String value)
  {
    setAttributeInternal(TARGETYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TargetMonth
   */
  public String getTargetMonth()
  {
    return (String)getAttributeInternal(TARGETMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TargetMonth
   */
  public void setTargetMonth(String value)
  {
    setAttributeInternal(TARGETMONTH, value);
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
   * Gets the attribute value for the calculated attribute ReflectMethod
   */
  public String getReflectMethod()
  {
    return (String)getAttributeInternal(REFLECTMETHOD);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ReflectMethod
   */
  public void setReflectMethod(String value)
  {
    setAttributeInternal(REFLECTMETHOD, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TargetYearMonth
   */
  public String getTargetYearMonth()
  {
    return (String)getAttributeInternal(TARGETYEARMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TargetYearMonth
   */
  public void setTargetYearMonth(String value)
  {
    setAttributeInternal(TARGETYEARMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute NextYearMonth
   */
  public String getNextYearMonth()
  {
    return (String)getAttributeInternal(NEXTYEARMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute NextYearMonth
   */
  public void setNextYearMonth(String value)
  {
    setAttributeInternal(NEXTYEARMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseCode
   */
  public String getBaseCode()
  {
    return (String)getAttributeInternal(BASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseCode
   */
  public void setBaseCode(String value)
  {
    setAttributeInternal(BASECODE, value);
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
      case REFLECTMETHOD:
        return getReflectMethod();
      case TARGETYEAR:
        return getTargetYear();
      case TARGETMONTH:
        return getTargetMonth();
      case TARGETYEARMONTH:
        return getTargetYearMonth();
      case NEXTYEARMONTH:
        return getNextYearMonth();
      case BASECODE:
        return getBaseCode();
      case RESULTRENDER:
        return getResultRender();
      case READONLYFLG:
        return getReadOnlyFlg();
      case MYEMPLOYEENUMBER:
        return getMyEmployeeNumber();
      case MYFULLNAME:
        return getMyFullName();
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
      case REFLECTMETHOD:
        setReflectMethod((String)value);
        return;
      case TARGETYEAR:
        setTargetYear((String)value);
        return;
      case TARGETMONTH:
        setTargetMonth((String)value);
        return;
      case TARGETYEARMONTH:
        setTargetYearMonth((String)value);
        return;
      case NEXTYEARMONTH:
        setNextYearMonth((String)value);
        return;
      case BASECODE:
        setBaseCode((String)value);
        return;
      case RESULTRENDER:
        setResultRender((Boolean)value);
        return;
      case READONLYFLG:
        setReadOnlyFlg((Boolean)value);
        return;
      case MYEMPLOYEENUMBER:
        setMyEmployeeNumber((String)value);
        return;
      case MYFULLNAME:
        setMyFullName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ResultRender
   */
  public Boolean getResultRender()
  {
    return (Boolean)getAttributeInternal(RESULTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ResultRender
   */
  public void setResultRender(Boolean value)
  {
    setAttributeInternal(RESULTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ReadOnlyFlg
   */
  public Boolean getReadOnlyFlg()
  {
    return (Boolean)getAttributeInternal(READONLYFLG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ReadOnlyFlg
   */
  public void setReadOnlyFlg(Boolean value)
  {
    setAttributeInternal(READONLYFLG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MyEmployeeNumber
   */
  public String getMyEmployeeNumber()
  {
    return (String)getAttributeInternal(MYEMPLOYEENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MyEmployeeNumber
   */
  public void setMyEmployeeNumber(String value)
  {
    setAttributeInternal(MYEMPLOYEENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MyFullName
   */
  public String getMyFullName()
  {
    return (String)getAttributeInternal(MYFULLNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MyFullName
   */
  public void setMyFullName(String value)
  {
    setAttributeInternal(MYFULLNAME, value);
  }





}