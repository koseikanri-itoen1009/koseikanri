/*============================================================================
* �t�@�C���� : XxcsoTaskAppSearchVORowImpl
* �T�v����   : �T�������󋵏Ɖ�^�����p�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-06 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * �X�P�W���[���w�胊�[�W�������������邽�߂̃r���[�s�N���X�ł��B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoTaskAppSearchVORowImpl extends OAViewRowImpl 
{

  protected static final int DATESCH = 0;
  protected static final int BASECODE = 1;
  protected static final int BASENAME = 2;
  protected static final int BASELINEBASECODE = 3;
  protected static final int LOGINRESOURCEID = 4;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoTaskAppSearchVORowImpl()
  {
  }

  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case DATESCH:
        return getDateSch();
      case BASECODE:
        return getBaseCode();
      case BASENAME:
        return getBaseName();
      case BASELINEBASECODE:
        return getBaseLineBaseCode();
      case LOGINRESOURCEID:
        return getLoginResourceId();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case DATESCH:
        setDateSch((Date)value);
        return;
      case BASECODE:
        setBaseCode((String)value);
        return;
      case BASENAME:
        setBaseName((String)value);
        return;
      case BASELINEBASECODE:
        setBaseLineBaseCode((String)value);
        return;
      case LOGINRESOURCEID:
        setLoginResourceId((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DateSch
   */
  public Date getDateSch()
  {
    return (Date)getAttributeInternal(DATESCH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DateSch
   */
  public void setDateSch(Date value)
  {
    setAttributeInternal(DATESCH, value);
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

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseLineBaseCode
   */
  public String getBaseLineBaseCode()
  {
    return (String)getAttributeInternal(BASELINEBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseLineBaseCode
   */
  public void setBaseLineBaseCode(String value)
  {
    setAttributeInternal(BASELINEBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LoginResourceId
   */
  public Number getLoginResourceId()
  {
    return (Number)getAttributeInternal(LOGINRESOURCEID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LoginResourceId
   */
  public void setLoginResourceId(Number value)
  {
    setAttributeInternal(LOGINRESOURCEID, value);
  }













}