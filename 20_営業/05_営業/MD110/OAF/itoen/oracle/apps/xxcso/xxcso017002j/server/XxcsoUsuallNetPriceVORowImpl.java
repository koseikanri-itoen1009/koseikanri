/*============================================================================
* ファイル名 : XxcsoUsuallyDelivPriceVORowImpl
* 概要説明   : 通常NET価格ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2011-04-13 1.0  SCS吉元強樹  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * 通常NET価格を導出するためのビュー行クラスです。
 * @author  SCS吉元強樹
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoUsuallNetPriceVORowImpl extends OAViewRowImpl 
{


  protected static final int USUALLNETPRICE = 0;
  protected static final int LASTUPDATEDATE = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoUsuallNetPriceVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UsuallNetPrice
   */
  public String getUsuallNetPrice()
  {
    return (String)getAttributeInternal(USUALLNETPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UsuallNetPrice
   */
  public void setUsuallNetPrice(String value)
  {
    setAttributeInternal(USUALLNETPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LastUpdateDate
   */
  public Date getLastUpdateDate()
  {
    return (Date)getAttributeInternal(LASTUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LastUpdateDate
   */
  public void setLastUpdateDate(Date value)
  {
    setAttributeInternal(LASTUPDATEDATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case USUALLNETPRICE:
        return getUsuallNetPrice();
      case LASTUPDATEDATE:
        return getLastUpdateDate();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case USUALLNETPRICE:
        setUsuallNetPrice((String)value);
        return;
      case LASTUPDATEDATE:
        setLastUpdateDate((Date)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}