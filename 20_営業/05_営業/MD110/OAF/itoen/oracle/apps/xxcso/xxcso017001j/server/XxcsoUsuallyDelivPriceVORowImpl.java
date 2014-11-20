/*============================================================================
* �t�@�C���� : XxcsoUsuallyDelivPriceVORowImpl
* �T�v����   : �ʏ�X�[���i�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-10-31 1.0  SCS�y���    �V�K�쐬
*============================================================================
*/

package itoen.oracle.apps.xxcso.xxcso017001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Date;
/*******************************************************************************
 * �ʏ�X�[���i���o�͂��邽�߂̃r���[�s�N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoUsuallyDelivPriceVORowImpl extends OAViewRowImpl 
{










  protected static final int USUALLYDELIVPRICE = 0;
  protected static final int LASTUPDATEDATE = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoUsuallyDelivPriceVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UsuallyDelivPrice
   */
  public String getUsuallyDelivPrice()
  {
    return (String)getAttributeInternal(USUALLYDELIVPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UsuallyDelivPrice
   */
  public void setUsuallyDelivPrice(String value)
  {
    setAttributeInternal(USUALLYDELIVPRICE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case USUALLYDELIVPRICE:
        return getUsuallyDelivPrice();
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
      case USUALLYDELIVPRICE:
        setUsuallyDelivPrice((String)value);
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