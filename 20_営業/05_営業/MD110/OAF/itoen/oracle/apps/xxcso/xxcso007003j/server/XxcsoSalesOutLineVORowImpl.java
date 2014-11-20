/*============================================================================
* ファイル名 : XxcsoSalesOutLineVORowImpl
* 概要説明   : 商談概要取得用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-28 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007003j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 商談概要を取得するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesOutLineVORowImpl extends OAViewRowImpl 
{


  protected static final int LEADNUMBER = 0;
  protected static final int DESCRIPTION = 1;
  protected static final int PARTYNAME = 2;
  protected static final int LEADID = 3;
  protected static final int NOTIFYSUBJECT = 4;
  protected static final int BASELINEBASECODE = 5;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesOutLineVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LeadNumber
   */
  public String getLeadNumber()
  {
    return (String)getAttributeInternal(LEADNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LeadNumber
   */
  public void setLeadNumber(String value)
  {
    setAttributeInternal(LEADNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Description
   */
  public String getDescription()
  {
    return (String)getAttributeInternal(DESCRIPTION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Description
   */
  public void setDescription(String value)
  {
    setAttributeInternal(DESCRIPTION, value);
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
      case LEADNUMBER:
        return getLeadNumber();
      case DESCRIPTION:
        return getDescription();
      case PARTYNAME:
        return getPartyName();
      case LEADID:
        return getLeadId();
      case NOTIFYSUBJECT:
        return getNotifySubject();
      case BASELINEBASECODE:
        return getBaselineBaseCode();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case LEADNUMBER:
        setLeadNumber((String)value);
        return;
      case DESCRIPTION:
        setDescription((String)value);
        return;
      case PARTYNAME:
        setPartyName((String)value);
        return;
      case LEADID:
        setLeadId((Number)value);
        return;
      case NOTIFYSUBJECT:
        setNotifySubject((String)value);
        return;
      case BASELINEBASECODE:
        setBaselineBaseCode((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LeadId
   */
  public Number getLeadId()
  {
    return (Number)getAttributeInternal(LEADID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LeadId
   */
  public void setLeadId(Number value)
  {
    setAttributeInternal(LEADID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute NotifySubject
   */
  public String getNotifySubject()
  {
    return (String)getAttributeInternal(NOTIFYSUBJECT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute NotifySubject
   */
  public void setNotifySubject(String value)
  {
    setAttributeInternal(NOTIFYSUBJECT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaselineBaseCode
   */
  public String getBaselineBaseCode()
  {
    return (String)getAttributeInternal(BASELINEBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaselineBaseCode
   */
  public void setBaselineBaseCode(String value)
  {
    setAttributeInternal(BASELINEBASECODE, value);
  }
}