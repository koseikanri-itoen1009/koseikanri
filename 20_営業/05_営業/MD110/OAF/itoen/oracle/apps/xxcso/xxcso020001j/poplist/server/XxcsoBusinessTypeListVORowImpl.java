/*============================================================================
* ファイル名 : XxcsoBusinessTypeListVORowImpl
* 概要説明   : 業種ポップリスト用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-18 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.poplist.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * 業種に表示するポップリストのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoBusinessTypeListVORowImpl extends OAViewRowImpl 
{


  protected static final int LOOKUPCODE = 0;
  protected static final int MEANING = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoBusinessTypeListVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LookupCode
   */
  public String getLookupCode()
  {
    return (String)getAttributeInternal(LOOKUPCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LookupCode
   */
  public void setLookupCode(String value)
  {
    setAttributeInternal(LOOKUPCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Meaning
   */
  public String getMeaning()
  {
    return (String)getAttributeInternal(MEANING);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Meaning
   */
  public void setMeaning(String value)
  {
    setAttributeInternal(MEANING, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case LOOKUPCODE:
        return getLookupCode();
      case MEANING:
        return getMeaning();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case LOOKUPCODE:
        setLookupCode((String)value);
        return;
      case MEANING:
        setMeaning((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}