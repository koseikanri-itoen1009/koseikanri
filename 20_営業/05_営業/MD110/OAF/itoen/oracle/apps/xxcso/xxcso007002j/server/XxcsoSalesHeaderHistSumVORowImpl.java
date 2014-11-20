/*============================================================================
* ファイル名 : XxcsoSalesHeaderHistSumVORowImpl
* 概要説明   : 商談決定情報履歴ヘッダ取得用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-09 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007002j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 商談決定情報履歴ヘッダを取得するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesHeaderHistSumVORowImpl extends OAViewRowImpl 
{


  protected static final int LEADNUMBER = 0;
  protected static final int LEADDESCRIPTION = 1;
  protected static final int PARTYNAME = 2;
  protected static final int OTHERCONTENT = 3;
  protected static final int LEADID = 4;
  protected static final int SALESDASHBOADUSEFLAG = 5;
  protected static final int LEADDESCRIPTIONLINKRENDER = 6;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesHeaderHistSumVORowImpl()
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
   * Gets the attribute value for the calculated attribute LeadDescription
   */
  public String getLeadDescription()
  {
    return (String)getAttributeInternal(LEADDESCRIPTION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LeadDescription
   */
  public void setLeadDescription(String value)
  {
    setAttributeInternal(LEADDESCRIPTION, value);
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
      case LEADNUMBER:
        return getLeadNumber();
      case LEADDESCRIPTION:
        return getLeadDescription();
      case PARTYNAME:
        return getPartyName();
      case OTHERCONTENT:
        return getOtherContent();
      case LEADID:
        return getLeadId();
      case SALESDASHBOADUSEFLAG:
        return getSalesDashboadUseFlag();
      case LEADDESCRIPTIONLINKRENDER:
        return getLeadDescriptionLinkRender();
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
      case LEADDESCRIPTION:
        setLeadDescription((String)value);
        return;
      case PARTYNAME:
        setPartyName((String)value);
        return;
      case OTHERCONTENT:
        setOtherContent((String)value);
        return;
      case LEADID:
        setLeadId((Number)value);
        return;
      case SALESDASHBOADUSEFLAG:
        setSalesDashboadUseFlag((String)value);
        return;
      case LEADDESCRIPTIONLINKRENDER:
        setLeadDescriptionLinkRender((Boolean)value);
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
   * Gets the attribute value for the calculated attribute SalesDashboadUseFlag
   */
  public String getSalesDashboadUseFlag()
  {
    return (String)getAttributeInternal(SALESDASHBOADUSEFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SalesDashboadUseFlag
   */
  public void setSalesDashboadUseFlag(String value)
  {
    setAttributeInternal(SALESDASHBOADUSEFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LeadDescriptionLinkRender
   */
  public Boolean getLeadDescriptionLinkRender()
  {
    return (Boolean)getAttributeInternal(LEADDESCRIPTIONLINKRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LeadDescriptionLinkRender
   */
  public void setLeadDescriptionLinkRender(Boolean value)
  {
    setAttributeInternal(LEADDESCRIPTIONLINKRENDER, value);
  }
}