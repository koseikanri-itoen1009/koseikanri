/*============================================================================
* ファイル名 : XxcsoSpDecisionHeadersSummuryVORowImpl
* 概要説明   : SP専決ヘッダサマリ情報取得ビュー行オブジェクトクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2015-02-02 1.0  SCSK山下翔太 新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
/*******************************************************************************
 * SP専決ヘッダサマリ情報取得ビュー行オブジェクトクラス
 * @author  SCSK山下翔太
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionHeadersSummuryVORowImpl extends OAViewRowImpl 
{


  protected static final int SPDECISIONHEADERID = 0;
  protected static final int SPDECISIONNUMBER = 1;
  protected static final int INSTALLSUPPTYPE = 2;
  protected static final int ELECTRICPAYMENTTYPE = 3;
  protected static final int INTROCHGTYPE = 4;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionHeadersSummuryVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoSpDecisionHeadersVEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoSpDecisionHeadersVEOImpl getXxcsoSpDecisionHeadersVEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoSpDecisionHeadersVEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for SP_DECISION_HEADER_ID using the alias name SpDecisionHeaderId
   */
  public Number getSpDecisionHeaderId()
  {
    return (Number)getAttributeInternal(SPDECISIONHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SP_DECISION_HEADER_ID using the alias name SpDecisionHeaderId
   */
  public void setSpDecisionHeaderId(Number value)
  {
    setAttributeInternal(SPDECISIONHEADERID, value);
  }

  /**
   * 
   * Gets the attribute value for SP_DECISION_NUMBER using the alias name SpDecisionNumber
   */
  public String getSpDecisionNumber()
  {
    return (String)getAttributeInternal(SPDECISIONNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SP_DECISION_NUMBER using the alias name SpDecisionNumber
   */
  public void setSpDecisionNumber(String value)
  {
    setAttributeInternal(SPDECISIONNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_SUPP_TYPE using the alias name InstallSuppType
   */
  public String getInstallSuppType()
  {
    return (String)getAttributeInternal(INSTALLSUPPTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_SUPP_TYPE using the alias name InstallSuppType
   */
  public void setInstallSuppType(String value)
  {
    setAttributeInternal(INSTALLSUPPTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for ELECTRIC_PAYMENT_TYPE using the alias name ElectricPaymentType
   */
  public String getElectricPaymentType()
  {
    return (String)getAttributeInternal(ELECTRICPAYMENTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ELECTRIC_PAYMENT_TYPE using the alias name ElectricPaymentType
   */
  public void setElectricPaymentType(String value)
  {
    setAttributeInternal(ELECTRICPAYMENTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for INTRO_CHG_TYPE using the alias name IntroChgType
   */
  public String getIntroChgType()
  {
    return (String)getAttributeInternal(INTROCHGTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INTRO_CHG_TYPE using the alias name IntroChgType
   */
  public void setIntroChgType(String value)
  {
    setAttributeInternal(INTROCHGTYPE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPDECISIONHEADERID:
        return getSpDecisionHeaderId();
      case SPDECISIONNUMBER:
        return getSpDecisionNumber();
      case INSTALLSUPPTYPE:
        return getInstallSuppType();
      case ELECTRICPAYMENTTYPE:
        return getElectricPaymentType();
      case INTROCHGTYPE:
        return getIntroChgType();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPDECISIONHEADERID:
        setSpDecisionHeaderId((Number)value);
        return;
      case SPDECISIONNUMBER:
        setSpDecisionNumber((String)value);
        return;
      case INSTALLSUPPTYPE:
        setInstallSuppType((String)value);
        return;
      case ELECTRICPAYMENTTYPE:
        setElectricPaymentType((String)value);
        return;
      case INTROCHGTYPE:
        setIntroChgType((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}