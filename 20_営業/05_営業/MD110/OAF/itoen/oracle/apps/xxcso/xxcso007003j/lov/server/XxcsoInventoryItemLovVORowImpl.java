/*============================================================================
* ファイル名 : XxcsoInventoryItemLovVORowImpl
* 概要説明   : 品目コードLOVビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-10 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007003j.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 品目コードLOVビュー行クラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInventoryItemLovVORowImpl extends OAViewRowImpl 
{
  protected static final int INVENTORYITEMID = 0;


  protected static final int INVENTORYITEMCODE = 1;
  protected static final int ITEMSHORTNAME = 2;
  protected static final int CASEINCNUM = 3;
  protected static final int JANCODE = 4;
  protected static final int ITFCODE = 5;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInventoryItemLovVORowImpl()
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
   * Gets the attribute value for the calculated attribute CaseIncNum
   */
  public String getCaseIncNum()
  {
    return (String)getAttributeInternal(CASEINCNUM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CaseIncNum
   */
  public void setCaseIncNum(String value)
  {
    setAttributeInternal(CASEINCNUM, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute JanCode
   */
  public String getJanCode()
  {
    return (String)getAttributeInternal(JANCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute JanCode
   */
  public void setJanCode(String value)
  {
    setAttributeInternal(JANCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ItfCode
   */
  public String getItfCode()
  {
    return (String)getAttributeInternal(ITFCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ItfCode
   */
  public void setItfCode(String value)
  {
    setAttributeInternal(ITFCODE, value);
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
      case CASEINCNUM:
        return getCaseIncNum();
      case JANCODE:
        return getJanCode();
      case ITFCODE:
        return getItfCode();
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
      case CASEINCNUM:
        setCaseIncNum((String)value);
        return;
      case JANCODE:
        setJanCode((String)value);
        return;
      case ITFCODE:
        setItfCode((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}