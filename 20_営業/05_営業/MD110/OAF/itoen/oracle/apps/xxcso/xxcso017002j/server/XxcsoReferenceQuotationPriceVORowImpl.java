/*============================================================================
* �t�@�C���� : XxcsoReferenceQuotationPriceVORowImpl
* �T�v����   : ���l�Z�o�p�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS�y���    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
/*******************************************************************************
 * ���l�̎Z�o�����邽�߂̃r���[�s�N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoReferenceQuotationPriceVORowImpl extends OAViewRowImpl 
{







  protected static final int QUOTATIONPRICE = 0;
  protected static final int LASTUPDATEDATE = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoReferenceQuotationPriceVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuotationPrice
   */
  public Number getQuotationPrice()
  {
    return (Number)getAttributeInternal(QUOTATIONPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuotationPrice
   */
  public void setQuotationPrice(Number value)
  {
    setAttributeInternal(QUOTATIONPRICE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case QUOTATIONPRICE:
        return getQuotationPrice();
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
      case QUOTATIONPRICE:
        setQuotationPrice((Number)value);
        return;
      case LASTUPDATEDATE:
        setLastUpdateDate((Date)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
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
}