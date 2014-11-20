/*============================================================================
* ファイル名 : XxcsoSpDecisionNotificationVORowImpl
* 概要説明   : SP専決通知画面初期値用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-17 1.0   SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * SP専決通知画面の初期値を設定するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionNotificationVORowImpl extends OAViewRowImpl 
{


  protected static final int MESSAGETEXT = 0;
  protected static final int SPDECISIONNUMMESSAGE = 1;
  protected static final int APPLICATIONDATE = 2;
  protected static final int APPLYBASENAME = 3;
  protected static final int APPLYUSERNAME = 4;
  protected static final int APPLYCLASSNAME = 5;
  protected static final int SPDECISIONHEADERID = 6;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionNotificationVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MessageText
   */
  public String getMessageText()
  {
    return (String)getAttributeInternal(MESSAGETEXT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MessageText
   */
  public void setMessageText(String value)
  {
    setAttributeInternal(MESSAGETEXT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SpDecisionNumMessage
   */
  public String getSpDecisionNumMessage()
  {
    return (String)getAttributeInternal(SPDECISIONNUMMESSAGE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SpDecisionNumMessage
   */
  public void setSpDecisionNumMessage(String value)
  {
    setAttributeInternal(SPDECISIONNUMMESSAGE, value);
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
   * Gets the attribute value for the calculated attribute ApplyUserName
   */
  public String getApplyUserName()
  {
    return (String)getAttributeInternal(APPLYUSERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApplyUserName
   */
  public void setApplyUserName(String value)
  {
    setAttributeInternal(APPLYUSERNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApplyClassName
   */
  public String getApplyClassName()
  {
    return (String)getAttributeInternal(APPLYCLASSNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApplyClassName
   */
  public void setApplyClassName(String value)
  {
    setAttributeInternal(APPLYCLASSNAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case MESSAGETEXT:
        return getMessageText();
      case SPDECISIONNUMMESSAGE:
        return getSpDecisionNumMessage();
      case APPLICATIONDATE:
        return getApplicationDate();
      case APPLYBASENAME:
        return getApplyBaseName();
      case APPLYUSERNAME:
        return getApplyUserName();
      case APPLYCLASSNAME:
        return getApplyClassName();
      case SPDECISIONHEADERID:
        return getSpDecisionHeaderId();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case MESSAGETEXT:
        setMessageText((String)value);
        return;
      case SPDECISIONNUMMESSAGE:
        setSpDecisionNumMessage((String)value);
        return;
      case APPLICATIONDATE:
        setApplicationDate((Date)value);
        return;
      case APPLYBASENAME:
        setApplyBaseName((String)value);
        return;
      case APPLYUSERNAME:
        setApplyUserName((String)value);
        return;
      case APPLYCLASSNAME:
        setApplyClassName((String)value);
        return;
      case SPDECISIONHEADERID:
        setSpDecisionHeaderId((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
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
}