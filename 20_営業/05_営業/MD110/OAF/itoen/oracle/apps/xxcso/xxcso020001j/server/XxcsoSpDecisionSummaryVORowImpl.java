/*============================================================================
* ファイル名 : XxcsoSpDecisionSummaryVORowImpl
* 概要説明   : SP専決書検索結果用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-16 1.0   SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * SP専決書検索画面の検索結果を取得するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionSummaryVORowImpl extends OAViewRowImpl 
{


  protected static final int PARTYNAME = 0;
  protected static final int SPDECISIONNUMBER = 1;
  protected static final int FULLNAME = 2;
  protected static final int APPLICATIONDATE = 3;
  protected static final int APPROVALCOMPLETEDATE = 4;
  protected static final int STATUSNAME = 5;
  protected static final int SPDECISIONHEADERID = 6;
  protected static final int SELECTFLAG = 7;
  protected static final int ORIGDATATAXDATE = 8;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionSummaryVORowImpl()
  {
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
   * Gets the attribute value for the calculated attribute ApplicationDate
   */
  public Date getApplicationDate()
  {
    return (Date)getAttributeInternal(APPLICATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApplicationDate
   */
  public void setApplicationDate(Date value)
  {
    setAttributeInternal(APPLICATIONDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApprovalCompleteDate
   */
  public Date getApprovalCompleteDate()
  {
    return (Date)getAttributeInternal(APPROVALCOMPLETEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApprovalCompleteDate
   */
  public void setApprovalCompleteDate(Date value)
  {
    setAttributeInternal(APPROVALCOMPLETEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute StatusName
   */
  public String getStatusName()
  {
    return (String)getAttributeInternal(STATUSNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute StatusName
   */
  public void setStatusName(String value)
  {
    setAttributeInternal(STATUSNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SpDecisionHeaderId
   */
  public Number getSpDecisionHeaderId()
  {
    return (Number)getAttributeInternal(SPDECISIONHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SpDecisionHeaderId
   */
  public void setSpDecisionHeaderId(Number value)
  {
    setAttributeInternal(SPDECISIONHEADERID, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case PARTYNAME:
        return getPartyName();
      case SPDECISIONNUMBER:
        return getSpDecisionNumber();
      case FULLNAME:
        return getFullName();
      case APPLICATIONDATE:
        return getApplicationDate();
      case APPROVALCOMPLETEDATE:
        return getApprovalCompleteDate();
      case STATUSNAME:
        return getStatusName();
      case SPDECISIONHEADERID:
        return getSpDecisionHeaderId();
      case SELECTFLAG:
        return getSelectFlag();
      case ORIGDATATAXDATE:
        return getOrigDataTaxDate();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case PARTYNAME:
        setPartyName((String)value);
        return;
      case SPDECISIONNUMBER:
        setSpDecisionNumber((String)value);
        return;
      case FULLNAME:
        setFullName((String)value);
        return;
      case APPLICATIONDATE:
        setApplicationDate((Date)value);
        return;
      case APPROVALCOMPLETEDATE:
        setApprovalCompleteDate((Date)value);
        return;
      case STATUSNAME:
        setStatusName((String)value);
        return;
      case SPDECISIONHEADERID:
        setSpDecisionHeaderId((Number)value);
        return;
      case SELECTFLAG:
        setSelectFlag((String)value);
        return;
      case ORIGDATATAXDATE:
        setOrigDataTaxDate((Date)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SelectFlag
   */
  public String getSelectFlag()
  {
    return (String)getAttributeInternal(SELECTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SelectFlag
   */
  public void setSelectFlag(String value)
  {
    setAttributeInternal(SELECTFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OrigDataTaxDate
   */
  public Date getOrigDataTaxDate()
  {
    return (Date)getAttributeInternal(ORIGDATATAXDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OrigDataTaxDate
   */
  public void setOrigDataTaxDate(Date value)
  {
    setAttributeInternal(ORIGDATATAXDATE, value);
  }





}