/*============================================================================
* ファイル名 : XxcsoSalesPlanSearchVOImpl
* 概要説明   : 売上計画出力画面VO行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-19 1.0  SCS朴邦彦　  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso001001j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;

import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * 売上計画出力画面VO行クラス
 * @author  SCS朴邦彦
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesPlanSearchVORowImpl extends OAViewRowImpl 
{


  protected static final int BUSINESSYEAR = 0;
  protected static final int BASECODE = 1;
  protected static final int BASENAME = 2;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesPlanSearchVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BusinessYear
   */
  public String getBusinessYear()
  {
    return (String)getAttributeInternal(BUSINESSYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BusinessYear
   */
  public void setBusinessYear(String value)
  {
    setAttributeInternal(BUSINESSYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseCode
   */
  public String getBaseCode()
  {
    return (String)getAttributeInternal(BASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseCode
   */
  public void setBaseCode(String value)
  {
    setAttributeInternal(BASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseName
   */
  public String getBaseName()
  {
    return (String)getAttributeInternal(BASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseName
   */
  public void setBaseName(String value)
  {
    setAttributeInternal(BASENAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case BUSINESSYEAR:
        return getBusinessYear();
      case BASECODE:
        return getBaseCode();
      case BASENAME:
        return getBaseName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case BUSINESSYEAR:
        setBusinessYear((String)value);
        return;
      case BASECODE:
        setBaseCode((String)value);
        return;
      case BASENAME:
        setBaseName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}