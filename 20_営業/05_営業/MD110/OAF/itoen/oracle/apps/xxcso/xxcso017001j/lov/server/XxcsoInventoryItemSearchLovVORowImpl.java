/*============================================================================
* ファイル名 : XxcsoInventoryItemSearchLovVORowImpl
* 概要説明   : 商品コードLOV用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-21 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 商品コードのLOVのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInventoryItemSearchLovVORowImpl extends OAViewRowImpl 
{
  protected static final int INVENTORYITEMID = 0;


  protected static final int INVENTORYITEMCODE = 1;
  protected static final int ITEMSHORTNAME = 2;
  protected static final int BUSINESSPRICE = 3;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInventoryItemSearchLovVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InventoryItemId
   */
  public Number getInventoryItemId()
  {
    return (Number)getAttributeInternal(INVENTORYITEMID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InventoryItemId
   */
  public void setInventoryItemId(Number value)
  {
    setAttributeInternal(INVENTORYITEMID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InventoryItemCode
   */
  public String getInventoryItemCode()
  {
    return (String)getAttributeInternal(INVENTORYITEMCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InventoryItemCode
   */
  public void setInventoryItemCode(String value)
  {
    setAttributeInternal(INVENTORYITEMCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ItemShortName
   */
  public String getItemShortName()
  {
    return (String)getAttributeInternal(ITEMSHORTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ItemShortName
   */
  public void setItemShortName(String value)
  {
    setAttributeInternal(ITEMSHORTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BusinessPrice
   */
  public Number getBusinessPrice()
  {
    return (Number)getAttributeInternal(BUSINESSPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BusinessPrice
   */
  public void setBusinessPrice(Number value)
  {
    setAttributeInternal(BUSINESSPRICE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case INVENTORYITEMID:
        return getInventoryItemId();
      case INVENTORYITEMCODE:
        return getInventoryItemCode();
      case ITEMSHORTNAME:
        return getItemShortName();
      case BUSINESSPRICE:
        return getBusinessPrice();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case INVENTORYITEMID:
        setInventoryItemId((Number)value);
        return;
      case INVENTORYITEMCODE:
        setInventoryItemCode((String)value);
        return;
      case ITEMSHORTNAME:
        setItemShortName((String)value);
        return;
      case BUSINESSPRICE:
        setBusinessPrice((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}