/*============================================================================
* ファイル名 : XxccpOpenWorkListPVORowImpl
* 概要説明   : ワークリストプロパティビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-08-10 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxccp.xxccp010A01j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * オープンワークリストの表示／非表示を制御するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxccpOpenWorkListPVORowImpl extends OAViewRowImpl 
{



  protected static final int PROCESSDATE = 0;
  protected static final int SALESOPENWORKLISTRENDER = 1;
  protected static final int MFGOPENWORKLISTRENDER = 2;
  protected static final int SYSOPENWORKLISTRENDER = 3;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxccpOpenWorkListPVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ProcessDate
   */
  public Date getProcessDate()
  {
    return (Date)getAttributeInternal(PROCESSDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ProcessDate
   */
  public void setProcessDate(Date value)
  {
    setAttributeInternal(PROCESSDATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case PROCESSDATE:
        return getProcessDate();
      case SALESOPENWORKLISTRENDER:
        return getSalesOpenWorkListRender();
      case MFGOPENWORKLISTRENDER:
        return getMfgOpenWorkListRender();
      case SYSOPENWORKLISTRENDER:
        return getSysOpenWorkListRender();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case PROCESSDATE:
        setProcessDate((Date)value);
        return;
      case SALESOPENWORKLISTRENDER:
        setSalesOpenWorkListRender((Boolean)value);
        return;
      case MFGOPENWORKLISTRENDER:
        setMfgOpenWorkListRender((Boolean)value);
        return;
      case SYSOPENWORKLISTRENDER:
        setSysOpenWorkListRender((Boolean)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SalesOpenWorkListRender
   */
  public Boolean getSalesOpenWorkListRender()
  {
    return (Boolean)getAttributeInternal(SALESOPENWORKLISTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SalesOpenWorkListRender
   */
  public void setSalesOpenWorkListRender(Boolean value)
  {
    setAttributeInternal(SALESOPENWORKLISTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MfgOpenWorkListRender
   */
  public Boolean getMfgOpenWorkListRender()
  {
    return (Boolean)getAttributeInternal(MFGOPENWORKLISTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MfgOpenWorkListRender
   */
  public void setMfgOpenWorkListRender(Boolean value)
  {
    setAttributeInternal(MFGOPENWORKLISTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SysOpenWorkListRender
   */
  public Boolean getSysOpenWorkListRender()
  {
    return (Boolean)getAttributeInternal(SYSOPENWORKLISTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SysOpenWorkListRender
   */
  public void setSysOpenWorkListRender(Boolean value)
  {
    setAttributeInternal(SYSOPENWORKLISTRENDER, value);
  }
}