/*============================================================================
* ファイル名 : XxcsoSpDecisionSearchInitVORowImpl
* 概要説明   : SP専決書検索画面初期値用ビュー行クラス
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-16 1.0   SCS小川浩    新規作成
* 2011-04-25 1.1  SCS桐生和幸   [E_本稼動_07224]SP専決参照権限変更対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * SP専決書検索画面の初期値を設定するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionSearchInitVORowImpl extends OAViewRowImpl 
{


  protected static final int APPLYBASECODE = 0;
  protected static final int APPLYBASENAME = 1;
  protected static final int EMPLOYEENUMBER = 2;
  protected static final int FULLNAME = 3;
  protected static final int APPLYDATESTART = 4;
  protected static final int APPLYDATEEND = 5;
  protected static final int STATUS = 6;
  protected static final int SPDECISIONNUMBER = 7;
  protected static final int ACCOUNTNUMBER = 8;
  protected static final int PARTYNAME = 9;
  protected static final int CUSTACCOUNTID = 10;
  protected static final int SEARCHCLASS = 11;
  protected static final int COPYBUTTONRENDER = 12;
  protected static final int DETAILBUTTONRENDER = 13;
  protected static final int APPLYBASEUSERRENDER = 14;
  protected static final int INITACTPOBASECODE = 15;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionSearchInitVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApplyBaseCode
   */
  public String getApplyBaseCode()
  {
    return (String)getAttributeInternal(APPLYBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApplyBaseCode
   */
  public void setApplyBaseCode(String value)
  {
    setAttributeInternal(APPLYBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApplyBaseName
   */
  public String getApplyBaseName()
  {
    return (String)getAttributeInternal(APPLYBASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApplyBaseName
   */
  public void setApplyBaseName(String value)
  {
    setAttributeInternal(APPLYBASENAME, value);
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
   * Gets the attribute value for the calculated attribute ApplyDateStart
   */
  public Date getApplyDateStart()
  {
    return (Date)getAttributeInternal(APPLYDATESTART);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApplyDateStart
   */
  public void setApplyDateStart(Date value)
  {
    setAttributeInternal(APPLYDATESTART, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApplyDateEnd
   */
  public Date getApplyDateEnd()
  {
    return (Date)getAttributeInternal(APPLYDATEEND);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApplyDateEnd
   */
  public void setApplyDateEnd(Date value)
  {
    setAttributeInternal(APPLYDATEEND, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Status
   */
  public String getStatus()
  {
    return (String)getAttributeInternal(STATUS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Status
   */
  public void setStatus(String value)
  {
    setAttributeInternal(STATUS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SpDecisionNumber
   */
  public String getSpDecisionNumber()
  {
    return (String)getAttributeInternal(SPDECISIONNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SpDecisionNumber
   */
  public void setSpDecisionNumber(String value)
  {
    setAttributeInternal(SPDECISIONNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AccountNumber
   */
  public String getAccountNumber()
  {
    return (String)getAttributeInternal(ACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AccountNumber
   */
  public void setAccountNumber(String value)
  {
    setAttributeInternal(ACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PartyName
   */
  public String getPartyName()
  {
    return (String)getAttributeInternal(PARTYNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PartyName
   */
  public void setPartyName(String value)
  {
    setAttributeInternal(PARTYNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CustAccountId
   */
  public Number getCustAccountId()
  {
    return (Number)getAttributeInternal(CUSTACCOUNTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CustAccountId
   */
  public void setCustAccountId(Number value)
  {
    setAttributeInternal(CUSTACCOUNTID, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case APPLYBASECODE:
        return getApplyBaseCode();
      case APPLYBASENAME:
        return getApplyBaseName();
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case FULLNAME:
        return getFullName();
      case APPLYDATESTART:
        return getApplyDateStart();
      case APPLYDATEEND:
        return getApplyDateEnd();
      case STATUS:
        return getStatus();
      case SPDECISIONNUMBER:
        return getSpDecisionNumber();
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case PARTYNAME:
        return getPartyName();
      case CUSTACCOUNTID:
        return getCustAccountId();
      case SEARCHCLASS:
        return getSearchClass();
      case COPYBUTTONRENDER:
        return getCopyButtonRender();
      case DETAILBUTTONRENDER:
        return getDetailButtonRender();
      case APPLYBASEUSERRENDER:
        return getApplyBaseUserRender();
      case INITACTPOBASECODE:
        return getInitActPoBaseCode();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case APPLYBASECODE:
        setApplyBaseCode((String)value);
        return;
      case APPLYBASENAME:
        setApplyBaseName((String)value);
        return;
      case EMPLOYEENUMBER:
        setEmployeeNumber((String)value);
        return;
      case FULLNAME:
        setFullName((String)value);
        return;
      case APPLYDATESTART:
        setApplyDateStart((Date)value);
        return;
      case APPLYDATEEND:
        setApplyDateEnd((Date)value);
        return;
      case STATUS:
        setStatus((String)value);
        return;
      case SPDECISIONNUMBER:
        setSpDecisionNumber((String)value);
        return;
      case ACCOUNTNUMBER:
        setAccountNumber((String)value);
        return;
      case PARTYNAME:
        setPartyName((String)value);
        return;
      case CUSTACCOUNTID:
        setCustAccountId((Number)value);
        return;
      case SEARCHCLASS:
        setSearchClass((String)value);
        return;
      case COPYBUTTONRENDER:
        setCopyButtonRender((Boolean)value);
        return;
      case DETAILBUTTONRENDER:
        setDetailButtonRender((Boolean)value);
        return;
      case APPLYBASEUSERRENDER:
        setApplyBaseUserRender((Boolean)value);
        return;
      case INITACTPOBASECODE:
        setInitActPoBaseCode((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CopyButtonRender
   */
  public Boolean getCopyButtonRender()
  {
    return (Boolean)getAttributeInternal(COPYBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CopyButtonRender
   */
  public void setCopyButtonRender(Boolean value)
  {
    setAttributeInternal(COPYBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DetailButtonRender
   */
  public Boolean getDetailButtonRender()
  {
    return (Boolean)getAttributeInternal(DETAILBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DetailButtonRender
   */
  public void setDetailButtonRender(Boolean value)
  {
    setAttributeInternal(DETAILBUTTONRENDER, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute SearchClass
   */
  public String getSearchClass()
  {
    return (String)getAttributeInternal(SEARCHCLASS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SearchClass
   */
  public void setSearchClass(String value)
  {
    setAttributeInternal(SEARCHCLASS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApplyBaseUserRender
   */
  public Boolean getApplyBaseUserRender()
  {
    return (Boolean)getAttributeInternal(APPLYBASEUSERRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApplyBaseUserRender
   */
  public void setApplyBaseUserRender(Boolean value)
  {
    setAttributeInternal(APPLYBASEUSERRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InitActPoBaseCode
   */
  public String getInitActPoBaseCode()
  {
    return (String)getAttributeInternal(INITACTPOBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InitActPoBaseCode
   */
  public void setInitActPoBaseCode(String value)
  {
    setAttributeInternal(INITACTPOBASECODE, value);
  }





}