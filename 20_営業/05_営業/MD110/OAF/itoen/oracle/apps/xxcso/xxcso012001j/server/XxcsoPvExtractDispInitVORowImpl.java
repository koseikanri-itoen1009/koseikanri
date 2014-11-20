/*============================================================================
* �t�@�C���� : XxcsoPvExtractDispInitVOImpl
* �T�v����   : �p�[�\�i���C�Y�r���[�쐬��ʁ^���o���������l�擾�r���[�s�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-07 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/

package itoen.oracle.apps.xxcso.xxcso012001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * ���o���������l�擾�r���[�I�u�W�F�N�g���邽�߂̃r���[�N���X�ł��B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvExtractDispInitVORowImpl extends OAViewRowImpl 
{



  protected static final int BASECODE = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvExtractDispInitVORowImpl()
  {
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
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case BASECODE:
        return getBaseCode();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case BASECODE:
        setBaseCode((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}