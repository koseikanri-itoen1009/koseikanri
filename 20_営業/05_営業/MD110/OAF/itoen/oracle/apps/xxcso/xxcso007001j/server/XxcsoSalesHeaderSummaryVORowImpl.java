/*============================================================================
* ファイル名 : XxcsoSalesHeaderSummaryVORowImpl
* 概要説明   : 商談決定情報ヘッダ取得用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-09 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 商談決定情報ヘッダを取得するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesHeaderSummaryVORowImpl extends OAViewRowImpl 
{



  protected static final int OTHERCONTENT = 0;
  protected static final int LEADID = 1;
  protected static final int LEADUPDENABLED = 2;
  protected static final int FORWARDBUTTONRENDER = 3;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesHeaderSummaryVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OtherContent
   */
  public String getOtherContent()
  {
    return (String)getAttributeInternal(OTHERCONTENT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OtherContent
   */
  public void setOtherContent(String value)
  {
    setAttributeInternal(OTHERCONTENT, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case OTHERCONTENT:
        return getOtherContent();
      case LEADID:
        return getLeadId();
      case LEADUPDENABLED:
        return getLeadUpdEnabled();
      case FORWARDBUTTONRENDER:
        return getForwardButtonRender();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case OTHERCONTENT:
        setOtherContent((String)value);
        return;
      case LEADID:
        setLeadId((Number)value);
        return;
      case LEADUPDENABLED:
        setLeadUpdEnabled((String)value);
        return;
      case FORWARDBUTTONRENDER:
        setForwardButtonRender((Boolean)value);
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
   * Gets the attribute value for the calculated attribute LeadUpdEnabled
   */
  public String getLeadUpdEnabled()
  {
    return (String)getAttributeInternal(LEADUPDENABLED);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LeadUpdEnabled
   */
  public void setLeadUpdEnabled(String value)
  {
    setAttributeInternal(LEADUPDENABLED, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ForwardButtonRender
   */
  public Boolean getForwardButtonRender()
  {
    return (Boolean)getAttributeInternal(FORWARDBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ForwardButtonRender
   */
  public void setForwardButtonRender(Boolean value)
  {
    setAttributeInternal(FORWARDBUTTONRENDER, value);
  }
}