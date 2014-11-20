/*============================================================================
* ファイル名 : XxcsoSpDecisionHeaderLovVORowImpl
* 概要説明   : SP専決書番号ＬＯＶビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-10-31 1.0  SCS及川領    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010001j.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
/*******************************************************************************
 * SP専決書番号ＬＯＶを作成するためのビュー行クラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionHeaderLovVORowImpl extends OAViewRowImpl 
{


  protected static final int SPDECISIONNUMBER = 0;
  protected static final int APPROVALCOMPLETEDATE = 1;
  protected static final int SPDECISIONHEADERID = 2;
  protected static final int PARTYNAME = 3;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionHeaderLovVORowImpl()
  {
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
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPDECISIONNUMBER:
        return getSpDecisionNumber();
      case APPROVALCOMPLETEDATE:
        return getApprovalCompleteDate();
      case SPDECISIONHEADERID:
        return getSpDecisionHeaderId();
      case PARTYNAME:
        return getPartyName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPDECISIONNUMBER:
        setSpDecisionNumber((String)value);
        return;
      case APPROVALCOMPLETEDATE:
        setApprovalCompleteDate((Date)value);
        return;
      case SPDECISIONHEADERID:
        setSpDecisionHeaderId((Number)value);
        return;
      case PARTYNAME:
        setPartyName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}