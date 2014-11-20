/*============================================================================
* �t�@�C���� : XxcsoQuoteSearch2VORowImpl
* �T�v����   : ���ό����r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-22 1.0  SCS���g    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017006j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * ���ό����̔ł������͏ꍇ�̃r���[�s�N���X�ł��B
 * @author  SCS���g
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteSearch2VORowImpl extends OAViewRowImpl 
{












  protected static final int QUOTEHEADERID = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteSearch2VORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteHeaderId
   */
  public Number getQuoteHeaderId()
  {
    return (Number)getAttributeInternal(QUOTEHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteHeaderId
   */
  public void setQuoteHeaderId(Number value)
  {
    setAttributeInternal(QUOTEHEADERID, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case QUOTEHEADERID:
        return getQuoteHeaderId();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case QUOTEHEADERID:
        setQuoteHeaderId((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}